# Dev Training 아키텍처

## 개요

`terraform/environments/dev/training`은 dev 학습 파이프라인용 AWS 인프라를 구성하는 Terraform 스택입니다.
이 스택의 목적은 크게 세 가지입니다.

- 학습 파이프라인 데이터와 모델 아티팩트를 S3에 저장
- Lambda 기반 전처리 파이프라인을 스케줄 실행
- 향후 모델 학습 실행용 Spot EC2 러너 프로비저닝

현재 이 스택은 서빙 계층, 데이터베이스, Redis 캐시, private-only 네트워크는 만들지 않습니다.
또한 VPC, subnet, security group도 새로 생성하지 않고, 이미 존재하는 리소스를 재사용하는 방식으로 동작합니다.

## 생성되는 인프라

### 1. 네트워크

이 스택은 VPC와 subnet을 새로 생성하지 않습니다.
대신 Terraform 변수로 전달받은 기존 네트워크 리소스를 참조합니다.

- VPC ID: `existing_vpc_id`
- subnet ID: `existing_subnet_id`

중요한 점:

- 현재 입력값 기준으로 training runner는 기존 public subnet을 사용합니다.
- 따라서 인터넷 outbound, AWS API 접근, S3 접근, SSH 접속 가능 여부는 기존 네트워크 설정에 의존합니다.

### 2. 보안 그룹

이 스택은 security group도 새로 생성하지 않습니다.
대신 Terraform 변수로 전달받은 기존 security group을 사용합니다.

- security group IDs: `existing_security_group_ids`

중요한 점:

- 현재 입력값 기준으로 training runner는 `sg-0f6c5df9e93530f94` (`launch-wizard-2`)를 사용합니다.
- SSH 접속, outbound 허용, 기타 접근 제어는 이 기존 security group 설정에 의존합니다.

### 3. S3 Data Lake

`data_lake` 모듈은 S3 버킷 1개를 생성하며, 다음 설정이 적용됩니다.

- versioning 활성화
- SSE-S3 암호화 활성화
- public access 차단

또한 아래 prefix를 함께 생성합니다.

- `raw/`
- `processed/`
- `dataset/`
- `model-artifact/`

각 prefix의 용도는 다음과 같습니다.

- `raw/`: 수집한 원본 데이터
- `processed/`: 전처리 완료 데이터
- `dataset/`: 학습 입력용 데이터셋
- `model-artifact/`: 모델 아티팩트와 체크포인트

### 4. Duplicate Guard

`duplicate_guard` 모듈은 DynamoDB 테이블 1개를 생성합니다.

- 테이블 이름: `${project_name}-${environment}-crawl-duplicate-guard`
- billing mode: `PAY_PER_REQUEST`
- hash key: `article_key`
- TTL 필드: `expire_at`

용도:

- 크롤링 단계에서 중복 데이터 저장을 방지하기 위한 용도입니다.

중요한 점:

- 현재 중복 방지는 Redis가 아니라 DynamoDB 기반입니다.

### 5. Dead-Letter Queue

`crawl_dlq` 모듈은 Lambda 실패 처리를 위한 SQS queue 1개를 생성합니다.

용도:

- 비동기 Lambda 실행이 재시도 후에도 실패하면 메시지가 이 DLQ로 들어갑니다.

### 6. Lambda 파이프라인

현재 스택은 다음 세 개의 Lambda 함수를 생성합니다.

- `crawl`
- `preprocess`
- `falsify-news`

호출 흐름은 다음과 같습니다.

1. EventBridge가 `crawl`을 호출
2. `crawl`이 `preprocess`를 호출 가능
3. `preprocess`가 `falsify-news`를 호출 가능

각 Lambda에는 다음이 함께 구성됩니다.

- CloudWatch log group
- 로그 기록용 IAM 권한
- 필요한 prefix 범위로 제한된 S3 접근 권한
- DLQ 전송 권한
- 필요 시 DynamoDB 또는 다른 Lambda 호출 권한

현재 구현 상태:

- 실제 Lambda 코드는 `terraform/modules/pipeline/lambda_job/src/python/main.py`에 있는 placeholder 코드입니다.
- 현재는 전달받은 event와 environment를 로그에 남기고 성공 응답만 반환합니다.
- 실제 크롤링, 전처리, falsify-news 로직은 아직 연결되어 있지 않습니다.

### 7. EventBridge 스케줄러

현재 스택은 스케줄 1개를 생성합니다.

- `crawl_schedule`

용도:

- `crawl_schedule_expression` 값에 따라 `crawl` Lambda를 주기적으로 실행합니다.

중요한 점:

- 직접 스케줄되는 Lambda는 `crawl` 하나뿐입니다.
- `preprocess`, `falsify-news`는 각각 별도 스케줄이 아니라 Lambda 간 호출로 이어집니다.

### 8. Training Runner

`training_runner` 모듈은 Spot EC2 인스턴스 1개를 생성합니다.

구성 요소:

- 기존 public subnet 배치
- public IP 할당
- IAM instance profile
- Amazon SSM 관리 권한
- S3 아티팩트/체크포인트 접근 권한
- IMDSv2 강제

동작 방식:

- 부팅 시 user data에서 `awscli`를 설치
- `/opt/whatson-training/runtime.env`에 런타임 환경변수 기록
- `/opt/whatson-training/run-training.sh` 실행 스크립트 생성
- `training_entrypoint` 실행
- 로그는 `/var/log/whatson-training.log`에 기록

중요한 점:

- 이 인스턴스는 persistent Spot이며 interruption behavior는 `stop`입니다.
- `training_ami_id`가 비어 있으면 Canonical의 최신 Ubuntu 24.04 AMD64 AMI를 사용합니다.

## 데이터 흐름

현재 코드 기준으로 의도된 흐름은 다음과 같습니다.

1. EventBridge가 `crawl` Lambda를 실행합니다.
2. `crawl`이 `raw/` 아래에 원본 데이터를 쓰거나 준비합니다.
3. `crawl`이 `preprocess`를 호출합니다.
4. `preprocess`가 `processed/` 아래에 전처리 결과를 씁니다.
5. `preprocess`가 `falsify-news`를 호출합니다.
6. `falsify-news`가 `dataset/` 아래에 학습용 데이터셋 결과를 씁니다.
7. EC2 training runner가 이 데이터셋을 읽고 `model-artifact/` 아래에 체크포인트나 모델 아티팩트를 저장합니다.

다만 현재는 인프라 경로만 준비되어 있고, Lambda 코드와 학습 실행 스크립트는 placeholder 상태입니다.

## 출력값

이 스택은 다음 값을 output으로 제공합니다.

- `vpc_id`
- `public_subnet_ids`
- `data_lake_bucket`
- `duplicate_guard_table_name`
- `duplicate_guard_table_arn`
- `crawl_dlq_arn`
- `lambda_functions`
- `training_runner_instance_id`
- `training_runner_instance_profile`
- `training_runner_public_ip`

## 운영 메모

### 현재 이 스택이 만들지 않는 것

- RDS 없음
- ElastiCache Redis 없음
- VPC 신규 생성 없음
- subnet 신규 생성 없음
- security group 신규 생성 없음
- Lambda VPC attachment 없음

### EC2 기반 deploy 흐름과의 연결

현재 GitHub Actions 배포 흐름과 이 아키텍처는 잘 맞습니다.

1. GitHub Actions가 EC2에 SSH 접속
2. EC2에서 `git pull`로 코드 갱신
3. EC2가 자신의 AWS 인증 정보 사용
4. `scripts/training/provision-dev-training-from-cloudshell.sh`가 이 디렉터리에서 Terraform 실행

### 성공적인 apply를 위한 전제 조건

- EC2에 `terraform`이 설치되어 있어야 함
- EC2에 `aws` CLI가 설치되어 있어야 함
- EC2에서 `aws sts get-caller-identity`가 성공해야 함
- `terraform.tfvars`가 존재해야 함
- `data_lake_bucket_name`은 전역에서 유니크해야 함
- 재사용하는 VPC, subnet, security group이 실제로 존재해야 함

## 권장 다음 단계

- placeholder Lambda 코드를 실제 파이프라인 로직으로 교체
- training runner를 public으로 둘지, SSM/private 네트워크 기반으로 옮길지 결정
- `training_entrypoint`를 실제 학습 bootstrap 스크립트로 교체
- apply 전에 S3 버킷 이름의 전역 유니크 여부 확인
