# Training Recovery Checklist

## Terraform

- Run `terraform -chdir=terraform/environments/<env>/training init`
- Run `terraform -chdir=terraform/environments/<env>/training plan`
- Run `terraform -chdir=terraform/environments/<env>/training apply`

## Core Resource Checks

- VPC/subnets/route tables are created
- Security groups exist and attached to expected components
- Data lake S3 bucket exists with expected prefixes (`raw`, `processed`, `dataset`, `model-artifact`)
- Redis dedupe cache endpoint is reachable from Lambda/EC2 security groups
- SQS DLQ exists and ARN is referenced by Lambda invoke config

## Pipeline Checks

- Lambda functions (`crawl`, `preprocess`, `augment`) are deployed
- Lambda environment variables include expected bucket/prefix values
- EventBridge schedules are enabled and target the correct Lambda ARNs
- CloudWatch log groups for each Lambda exist

## Training Runner Checks

- EC2 instance profile/role is attached
- Training runner instance is running in expected private subnet
- Artifact/checkpoint prefixes are writable to S3

## Post-Apply Smoke

- Trigger one Lambda test invocation per stage
- Confirm no immediate DLQ spike
- Confirm one end-to-end path writes data to S3 prefixes
