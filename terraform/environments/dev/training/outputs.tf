output "vpc_id" {
  value = data.aws_vpc.existing.id
}

output "public_subnet_ids" {
  value = local.existing_public_subnet_ids
}

output "data_lake_bucket" {
  value = data.aws_s3_bucket.data_lake.bucket
}

output "duplicate_guard_table_name" {
  value = data.aws_dynamodb_table.duplicate_guard.name
}

output "duplicate_guard_table_arn" {
  value = data.aws_dynamodb_table.duplicate_guard.arn
}

output "crawl_dlq_arn" {
  value = data.aws_sqs_queue.crawl_dlq.arn
}

output "lambda_functions" {
  value = {
    crawl        = module.crawl_job.function_name
    preprocess   = module.preprocess_job.function_name
    falsify_news = module.falsify_news_job.function_name
  }
}

output "training_runner_instance_id" {
  value = module.training_runner.instance_id
}

output "training_runner_instance_profile" {
  value = module.training_runner.instance_profile_name
}

output "training_runner_public_ip" {
  value = module.training_runner.public_ip
}
