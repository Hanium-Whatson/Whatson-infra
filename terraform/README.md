# Terraform Structure for Whatson Architecture

## Layout
- `global/`: account-level shared setup (state/backend baseline)
- `modules/`: reusable AWS building blocks
- `environments/<env>/training`: crawler/preprocess/augmentation/training pipeline
- `environments/<env>/serving`: batch inference + read-only serving data path
- `environments/<env>/monitoring`: logs, alarms, dashboards, Grafana

## Architecture Mapping
- Data lake: `storage/s3_data_lake`
- Inference DB: `storage/rds_inference`
- Duplicate guard: `cache/redis_dedupe`
- Scheduler: `pipeline/eventbridge_scheduler`
- Jobs: `pipeline/lambda_job`
- Failure isolation: `pipeline/sqs_dlq`
- Batch inference runtime: `compute/batch_inference_ec2`
- Ops visibility: `observability/cloudwatch`, `observability/grafana`
