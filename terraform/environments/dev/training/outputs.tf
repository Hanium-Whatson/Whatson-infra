output "vpc_id" {
  value = data.aws_vpc.existing.id
}

output "public_subnet_ids" {
  value = local.existing_public_subnet_ids
}

output "data_lake_bucket" {
  value = var.data_lake_bucket_name
}

output "duplicate_guard_table_name" {
  value = local.duplicate_guard_table_name
}

output "duplicate_guard_table_arn" {
  value = local.duplicate_guard_table_arn
}

output "crawl_dlq_arn" {
  value = local.crawl_dlq_arn
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
