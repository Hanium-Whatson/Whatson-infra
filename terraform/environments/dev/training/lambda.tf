module "crawl_dlq" {
  source = "../../../modules/pipeline/sqs_dlq"
  name   = "${var.project_name}-${var.environment}-crawl-dlq"
}

module "crawl_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-crawl"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 900
  memory_size            = 1024
  dead_letter_target_arn = module.crawl_dlq.queue_arn
  s3_bucket_arn          = module.data_lake.bucket_arn
  s3_object_prefixes     = [local.raw_prefix]
  dynamodb_table_arn     = module.duplicate_guard.table_arn
  lambda_invoke_function_arns = [
    module.preprocess_job.function_arn,
  ]
  environment_variables = {
    DATA_LAKE_BUCKET           = module.data_lake.bucket_name
    RAW_PREFIX                 = local.raw_prefix
    DUPLICATE_GUARD_TABLE_NAME = module.duplicate_guard.table_name
    PREPROCESS_FUNCTION_NAME   = module.preprocess_job.function_name
    JOB_STAGE                  = "crawl"
  }
}

module "preprocess_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-preprocess"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 900
  memory_size            = 1024
  dead_letter_target_arn = module.crawl_dlq.queue_arn
  s3_bucket_arn          = module.data_lake.bucket_arn
  s3_object_prefixes     = [local.raw_prefix, local.processed_prefix]
  lambda_invoke_function_arns = [
    module.augment_job.function_arn,
  ]
  environment_variables = {
    DATA_LAKE_BUCKET       = module.data_lake.bucket_name
    RAW_PREFIX             = local.raw_prefix
    PROCESSED_PREFIX       = local.processed_prefix
    AUGMENT_FUNCTION_NAME  = module.augment_job.function_name
    JOB_STAGE              = "preprocess"
  }
}

module "augment_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-augment"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 900
  memory_size            = 1024
  dead_letter_target_arn = module.crawl_dlq.queue_arn
  s3_bucket_arn          = module.data_lake.bucket_arn
  s3_object_prefixes     = [local.processed_prefix, local.dataset_prefix]
  environment_variables = {
    DATA_LAKE_BUCKET = module.data_lake.bucket_name
    PROCESSED_PREFIX = local.processed_prefix
    DATASET_PREFIX   = local.dataset_prefix
    JOB_STAGE        = "augment"
  }
}
