# Dev Training Terraform 완성 계획

## Summary
`terraform/environments/dev/training`을 실제로 `terraform apply` 가능한 상태로 완성한다. 범위는 `network`, `security`, `S3 data lake`, `Redis dedupe`, `SQS DLQ`, `Lambda 작업군`, `EventBridge 스케줄`, `EC2 Spot 기반 학습 실행기`까지 포함한다. 문서화는 요청하신 경로인 `terraform/dev/guide.md`에 정리하고, 각 인프라의 역할·연관관계·운영 포인트를 자세히 적는다.

이번 설계의 핵심 원칙은 두 가지다.
- 지금은 AWS `EC2 Spot`으로 학습 실행기를 만든다.
- 나중에 `Runpod`로 옮기기 쉽도록, 학습 실행 인터페이스는 AMI 고정형이 아니라 “아티팩트 경로 + 실행 명령 + 환경변수 + 체크포인트 경로” 중심으로 느슨하게 잡는다.

## Key Changes
- 공통 모듈 구현
  - `foundation/network`: VPC, 2개 이상 private subnet, public subnet, IGW, NAT gateway, 라우팅까지 구현한다.
  - `foundation/security`: Lambda용 SG, EC2 학습기용 SG, 최소 IAM 역할/정책을 만든다.
  - `storage/s3_data_lake`: 단일 버킷 + `raw/`, `processed/`, `dataset/`, `model-artifact/` prefix 구조를 구현하고 버전닝, 기본 암호화, 퍼블릭 액세스 차단을 넣는다.
  - `cache/redis_dedupe`: ElastiCache Redis와 subnet group을 구현하고 endpoint를 출력한다.
  - `pipeline/sqs_dlq`: 비동기 Lambda 실패용 SQS DLQ를 구현한다.
  - `pipeline/lambda_job`: 재사용 가능한 Lambda 모듈로 완성한다. 플레이스홀더 함수 코드를 repo 안에 두고 `archive_file`로 패키징해 바로 배포 가능하게 만든다.
  - `pipeline/eventbridge_scheduler`: EventBridge rule/target/Lambda invoke permission까지 포함해 스케줄링을 완성한다.

- `dev/training` 스택 완성
  - `crawl`, `preprocess`, `augment`용 Lambda 3개를 만든다.
  - 각 Lambda에는 S3 bucket/prefix, Redis endpoint, DLQ ARN, 공통 태그, CloudWatch 로그 권한을 연결한다.
  - EventBridge 스케줄을 작업별로 분리한다.
  - `train` 단계는 Lambda가 아니라 EC2 Spot 실행기 모듈로 연결한다. 이 모듈은 launch template + IAM instance profile + spot instance request 성격으로 구현한다.
  - 학습 실행기는 user data에서 “지정된 스크립트/명령”을 실행하도록 하고, 체크포인트와 산출물은 S3 `model-artifact/` 아래에 저장하도록 강제한다.
  - 향후 Runpod 이전을 고려해 학습 실행 관련 입력은 `instance_type`, `container_image_or_artifact`, `entrypoint`, `env`, `checkpoint_prefix`처럼 일반화한다. AWS 고유 세부값은 모듈 내부에 최대한 가둔다.

- 환경 변수와 출력 정리
  - `terraform/environments/dev/training/providers.tf` 또는 별도 variables 파일에 학습기/스케줄용 입력 변수를 추가한다.
  - `terraform/environments/dev/training/terraform.tfvars.example`에는 바로 복사해 쓸 수 있는 예시값을 채운다.
  - 출력은 최소한 `vpc_id`, `private_subnet_ids`, `data_lake_bucket`, `redis_endpoint`, `crawl_dlq_arn`, Lambda 이름들, 학습 실행기 role/profile 관련 식별자를 제공한다.

- 문서 작성
  - `terraform/dev/guide.md`에 다음을 정리한다.
  - `architecture.md` 기준으로 dev training 인프라가 어떤 흐름으로 동작하는지
  - 각 구성요소의 역할: VPC, S3, Redis, SQS DLQ, Lambda, EventBridge, EC2 Spot
  - 왜 training에는 RDS가 없고 serving에서 RDS가 필요한지
  - 장애 시나리오 대응: crawl 실패, Lambda 재시도/DLQ, Spot interruption, 체크포인팅
  - 적용 방법: `init`, `validate`, `plan`, `apply`
  - 향후 Runpod 이전 시 바뀌는 부분과 그대로 유지되는 인터페이스

## Public APIs / Interfaces
- `pipeline/lambda_job` 모듈 입력을 확장한다.
  - 함수 이름, 런타임, 핸들러, timeout, memory, env 외에
  - `source_dir` 또는 내부 플레이스홀더 선택값
  - `role_policy_mode`
  - `subnet_ids`, `security_group_ids`
  - `s3_access`, `redis_access`, `cloudwatch_log_retention`
- `pipeline/eventbridge_scheduler` 모듈 입력을 확장한다.
  - `schedule_expression`
  - `target_arn`
  - 필요 시 `input_json`
- 학습 실행기용 새 모듈 인터페이스를 추가한다.
  - `name`
  - `subnet_id`
  - `security_group_ids`
  - `instance_type`
  - `spot_max_price` 또는 on-demand fallback 없음 명시
  - `artifact_bucket`
  - `checkpoint_prefix`
  - `entrypoint`
  - `environment_variables`
- `dev/training`용 추가 변수 예시
  - `crawl_schedule_expression`
  - `preprocess_schedule_expression`
  - `augment_schedule_expression`
  - `training_instance_type`
  - `training_entrypoint`
  - `training_environment_variables`

## Test Plan
- `terraform fmt -check -recursive`
- `terraform validate` for:
  - `terraform/environments/dev/training`
  - 변경한 재사용 모듈 참조 경로 전체
- `terraform plan` on `dev/training` with example tfvars
- 검증 시나리오
  - S3 bucket/prefix 출력이 정상인지
  - Redis endpoint가 Lambda env에 연결되는지
  - Lambda async DLQ 연결이 생성되는지
  - EventBridge가 각 Lambda를 invoke할 permission을 갖는지
  - 학습 실행기 IAM이 S3 artifact/checkpoint 경로에 접근 가능한지
  - Spot 중단 시 재개를 위한 체크포인트 경로가 문서와 변수에 반영되는지

## Assumptions
- 지금 턴에서는 계획만 확정하고, 다음 구현 턴에서 실제 Terraform 파일과 `terraform/dev/guide.md`를 작성한다.
- Lambda는 실제 서비스 코드가 아직 없으므로, “배포 가능성 검증용 플레이스홀더 함수”를 repo 내부에 포함한다.
- 모델 학습은 AWS 내부에서 우선 `EC2 Spot`으로 돌리고, 추후 `Runpod` 이전 시에도 재사용 가능하도록 입력 인터페이스를 일반화한다.
- `Runpod` 자체 리소스는 이번 범위에 넣지 않는다.
- 문서 경로는 사용자가 지정한 `terraform/dev/guide.md`를 우선 사용한다.
