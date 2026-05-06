# Dev Training Terraform Guide

## 개요

이 문서는 `md/architecture.md` 기준으로 `terraform/environments/dev/training` 스택이 어떤 인프라를 만들고, 각 구성요소가 어떤 역할을 담당하는지 정리한 가이드다.

dev training 스택의 목적은 다음과 같다.

- 수집용 원천 데이터를 안전하게 저장한다.
- 전처리와 데이터 증강 파이프라인을 서버리스로 반복 실행한다.
- Redis로 중복 수집을 빠르게 방지한다.
- 학습 산출물과 체크포인트를 S3에 저장하고, 현재는 EC2 Spot 기반 학습 실행기를 준비한다.

training 스택은 serving 스택과 역할이 다르다. training은 데이터 생성과 모델 산출물 적재가 중심이고, serving은 이미 만들어진 추론 결과를 빠르게 읽어 제공하는 경로가 중심이다. 그래서 training에는 RDS를 넣지 않았고, RDS는 `serving`에서 최종 결과 조회용으로 분리하는 구조를 유지한다.

## 생성되는 인프라

### 1. 네트워크

- VPC 1개
- Public subnet 1개
- Private subnet 1개
- Internet Gateway 1개
- NAT Gateway 1개
- Public/Private Route Table

역할:

- Lambda와 EC2 Spot 학습기가 private subnet에서 실행될 수 있게 한다.
- private subnet 리소스가 외부 패키지 다운로드나 AWS API 호출을 할 때 NAT를 통해 outbound 통신할 수 있게 한다.

### 2. 보안 그룹

- Lambda 전용 SG
- Redis 전용 SG
- EC2 training runner 전용 SG

역할:

- Lambda가 Redis 6379 포트로만 접근하게 제어한다.
- 학습 실행기는 현재 외부 inbound 없이 outbound만 허용한다.

### 3. S3 Data Lake

단일 버킷 1개와 아래 prefix를 생성한다.

- `raw/`
- `processed/`
- `dataset/`
- `model-artifact/`

역할:

- `raw/`: 크롤링 직후 원본 데이터
- `processed/`: 전처리 완료 데이터
- `dataset/`: 학습에 바로 투입할 수 있는 최종 데이터셋
- `model-artifact/`: 모델 산출물, 체크포인트, 향후 배포 전 아티팩트

설정:

- 버전닝 활성화
- 기본 SSE-S3 암호화
- 퍼블릭 액세스 전면 차단

### 4. Redis Dedupe Cache

- ElastiCache Redis replication group 1개
- ElastiCache subnet group 1개

역할:

- 크롤링 단계에서 기사 URL 또는 해시를 캐시해 중복 수집을 빠르게 차단한다.
- 같은 데이터가 재수집되어도 불필요한 후속 처리 비용이 커지지 않도록 한다.

### 5. SQS DLQ

- Lambda 비동기 실패 격리용 SQS queue 1개

역할:

- `crawl`, `preprocess`, `augment` Lambda가 재시도 후에도 실패하면 메시지를 DLQ로 보낸다.
- 전체 파이프라인을 멈추지 않고 실패 건만 별도로 분석할 수 있게 한다.

### 6. Lambda 작업군

구성:

- `crawl` Lambda
- `preprocess` Lambda
- `augment` Lambda

현재 상태:

- 실제 비즈니스 로직 대신 플레이스홀더 Python Lambda가 배포된다.
- 환경변수와 이벤트를 로그로 남기므로, 인프라 연결 상태와 권한 검증 용도로 바로 사용할 수 있다.

각 역할:

- `crawl`: 수집 시작점. `raw/`와 Redis endpoint를 사용한다.
- `preprocess`: `raw/`를 읽고 `processed/`를 만든다.
- `augment`: `processed/`를 읽고 `dataset/`을 만든다.

### 7. EventBridge 스케줄

구성:

- crawl schedule
- preprocess schedule
- augment schedule

역할:

- 각 Lambda를 일정 주기로 자동 실행한다.
- dev 기준 기본값은 `6시간`, `12시간`, `1일` 주기다.

### 8. EC2 Spot Training Runner

구성:

- Private subnet에 배치되는 Spot EC2 1대
- IAM role / instance profile
- S3 artifact/checkpoint 접근 권한
- SSM 관리 권한

역할:

- 현재 dev 환경의 학습 실행 주체다.
- 부팅 시 `training_entrypoint`를 실행한다.
- 체크포인트와 산출물은 S3 `model-artifact/` 아래에 저장하도록 설계했다.

중요한 설계 의도:

- 지금은 EC2 Spot을 쓰지만, 입력 인터페이스는 `entrypoint`, `environment_variables`, `checkpoint_prefix`, `artifact_prefix` 중심으로 잡았다.
- 이 덕분에 나중에 Runpod로 옮길 때도 상위 스택 계약은 유지하고, 어디서 실행하느냐만 바꾸는 방향으로 이전할 수 있다.

## 현재 파이프라인 흐름

1. EventBridge가 `crawl` Lambda를 주기적으로 호출한다.
2. `crawl` Lambda는 원천 데이터를 수집하고 `raw/` 저장을 가정한다.
3. `preprocess` Lambda가 `raw/`를 기반으로 `processed/`를 만든다.
4. `augment` Lambda가 `processed/`를 기반으로 `dataset/`을 만든다.
5. 학습 실행기는 `dataset/`을 입력으로 사용하고, 체크포인트와 모델 산출물을 `model-artifact/` 아래에 남긴다.

현재는 Lambda 쪽과 학습기 모두 플레이스홀더 실행이 포함되어 있으므로, 인프라 프로비저닝과 연결 검증을 먼저 완료한 뒤 실제 애플리케이션 코드를 교체하면 된다.

## 왜 training에 RDS가 없는가

`architecture.md`에서 RDS의 역할은 서비스 제공을 위한 최종 추론 결과 저장에 가깝다. training 스택은 아직 학습 데이터 생성과 모델 아티팩트 생성이 중심이므로 다음 이유로 RDS를 넣지 않았다.

- training 단계의 주 저장소는 S3 data lake가 더 적합하다.
- 학습 중간 산출물은 구조가 자주 바뀌므로 객체 스토리지가 유연하다.
- 서비스 조회 최적화는 serving 스택의 책임으로 분리하는 편이 운영상 명확하다.

## 장애 대응 관점

### 크롤링/전처리/증강 실패

- Lambda는 비동기 재시도 2회를 사용한다.
- 최종 실패는 SQS DLQ로 보낸다.
- 이후 DLQ 메시지를 기준으로 재처리하거나 원인 분석을 진행한다.

### 중복 수집

- Redis가 기사 키를 보관해 중복 데이터를 걸러낸다.
- 같은 데이터가 다시 들어와도 후속 비용이 늘어나지 않게 한다.

### Spot interruption

- 학습 실행기는 Spot 기반이다.
- 체크포인트 경로를 `model-artifact/checkpoints`로 고정해 재개 가능한 저장 위치를 먼저 마련했다.
- 실제 학습 코드에서는 주기적으로 체크포인트를 S3에 업로드하도록 맞추는 것이 중요하다.

### 향후 Runpod 이전

아래 항목은 최대한 유지된다.

- S3 bucket/prefix 구조
- 환경변수 계약
- 체크포인트 prefix
- 학습 entrypoint 개념

주로 바뀌는 항목은 아래다.

- EC2 IAM/instance profile
- EC2 user data
- AWS Spot 종속 설정

즉, 상위 환경 변수와 아티팩트 경로를 유지하면 이전 부담을 줄일 수 있다.

## 적용 방법

작업 디렉터리:

- `terraform/environments/dev/training`

권장 순서:

```powershell
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

시작 전 준비:

1. `terraform.tfvars.example`를 복사해 `terraform.tfvars`를 만든다.
2. `data_lake_bucket_name`을 전역에서 유일한 이름으로 바꾼다.
3. `training_entrypoint`를 실제 학습 bootstrap 스크립트에 맞게 수정한다.
4. GPU 드라이버 또는 커스텀 이미지가 필요하면 `training_ami_id`를 지정한다.

## 실제 운영 전에 바꿔야 할 가능성이 높은 항목

- `data_lake_bucket_name`
- `training_instance_type`
- `training_ami_id`
- `training_entrypoint`
- `training_environment_variables`

특히 GPU 학습을 바로 돌릴 계획이면 기본 Ubuntu AMI 대신 CUDA/드라이버가 포함된 커스텀 AMI 또는 사전 구성된 이미지 전략을 정하는 것이 좋다. 현재 기본값은 인프라 검증 우선 기준이다.
