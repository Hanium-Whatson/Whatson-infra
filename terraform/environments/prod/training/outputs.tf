output "data_lake_bucket" { value = module.data_lake.bucket_name }
output "redis_endpoint" { value = module.dedupe_cache.redis_endpoint }
