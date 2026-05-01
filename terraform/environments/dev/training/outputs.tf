output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "data_lake_bucket" {
  value = module.data_lake.bucket_name
}

output "redis_endpoint" {
  value = module.dedupe_cache.redis_endpoint
}

output "crawl_dlq_arn" {
  value = module.crawl_dlq.queue_arn
}

output "lambda_functions" {
  value = {
    crawl      = module.crawl_job.function_name
    preprocess = module.preprocess_job.function_name
    augment    = module.augment_job.function_name
  }
}

output "training_runner_instance_id" {
  value = module.training_runner.instance_id
}

output "training_runner_instance_profile" {
  value = module.training_runner.instance_profile_name
}
