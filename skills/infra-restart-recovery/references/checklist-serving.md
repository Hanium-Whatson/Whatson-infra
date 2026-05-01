# Serving Recovery Checklist

## Terraform

- Run `terraform -chdir=terraform/environments/<env>/serving init`
- Run `terraform -chdir=terraform/environments/<env>/serving plan`
- Run `terraform -chdir=terraform/environments/<env>/serving apply`

## Core Resource Checks

- Network and security groups are recreated correctly
- Inference compute resources are in running/healthy state
- Inference data stores and queues (if configured) are present

## API/Worker Checks

- Service runtime roles are attached and policies resolved
- Service environment variables and endpoints reference recreated resource IDs
- Background workers/cron/schedulers are reconnected

## Post-Apply Smoke

- Run health endpoint checks for serving API
- Run one inference request and verify response + persistence path
- Verify logs/metrics emission in CloudWatch
