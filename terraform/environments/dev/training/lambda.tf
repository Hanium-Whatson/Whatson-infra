module "crawl_dlq" {
  source = "../../../modules/pipeline/sqs_dlq"
  name   = "${var.project_name}-${var.environment}-crawl-dlq"
}

module "crawl_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-crawl"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 120
  memory_size            = 512
  dead_letter_target_arn = module.crawl_dlq.queue_arn
  subnet_ids             = module.network.private_subnet_ids
  security_group_ids     = [module.security.lambda_sg_id]
  s3_bucket_arn          = module.data_lake.bucket_arn
  s3_object_prefixes     = [local.raw_prefix]
  environment_variables = {
    DATA_LAKE_BUCKET = module.data_lake.bucket_name
    RAW_PREFIX       = local.raw_prefix
    REDIS_ENDPOINT   = module.dedupe_cache.redis_endpoint
    JOB_STAGE        = "crawl"
  }
}

module "preprocess_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-preprocess"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 180
  memory_size            = 512
  dead_letter_target_arn = module.crawl_dlq.queue_arn
  subnet_ids             = module.network.private_subnet_ids
  security_group_ids     = [module.security.lambda_sg_id]
  s3_bucket_arn          = module.data_lake.bucket_arn
  s3_object_prefixes     = [local.raw_prefix, local.processed_prefix]
  environment_variables = {
    DATA_LAKE_BUCKET = module.data_lake.bucket_name
    RAW_PREFIX       = local.raw_prefix
    PROCESSED_PREFIX = local.processed_prefix
    JOB_STAGE        = "preprocess"
  }
}

module "augment_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-augment"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 300
  memory_size            = 1024
  dead_letter_target_arn = module.crawl_dlq.queue_arn
  subnet_ids             = module.network.private_subnet_ids
  security_group_ids     = [module.security.lambda_sg_id]
  s3_bucket_arn          = module.data_lake.bucket_arn
  s3_object_prefixes     = [local.processed_prefix, local.dataset_prefix]
  environment_variables = {
    DATA_LAKE_BUCKET = module.data_lake.bucket_name
    PROCESSED_PREFIX = local.processed_prefix
    DATASET_PREFIX   = local.dataset_prefix
    JOB_STAGE        = "augment"
  }
}
