module "crawl_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-crawl"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 900
  memory_size            = 1024
  dead_letter_target_arn = local.crawl_dlq_arn
  s3_bucket_arn          = local.data_lake_bucket_arn
  s3_object_prefixes     = [local.raw_prefix]
  dynamodb_table_arn     = local.duplicate_guard_table_arn
  lambda_invoke_function_arns = [
    module.preprocess_job.function_arn,
  ]
  existing_role_arn = var.crawl_lambda_role_arn
  environment_variables = {
    DATA_LAKE_BUCKET           = var.data_lake_bucket_name
    RAW_PREFIX                 = local.raw_prefix
    DUPLICATE_GUARD_TABLE_NAME = local.duplicate_guard_table_name
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
  dead_letter_target_arn = local.crawl_dlq_arn
  s3_bucket_arn          = local.data_lake_bucket_arn
  s3_object_prefixes     = [local.raw_prefix, local.processed_prefix]
  lambda_invoke_function_arns = [
    module.falsify_news_job.function_arn,
  ]
  existing_role_arn = var.preprocess_lambda_role_arn
  environment_variables = {
    DATA_LAKE_BUCKET           = var.data_lake_bucket_name
    RAW_PREFIX                 = local.raw_prefix
    PROCESSED_PREFIX           = local.processed_prefix
    FALSIFY_NEWS_FUNCTION_NAME = module.falsify_news_job.function_name
    JOB_STAGE                  = "preprocess"
  }
}

module "falsify_news_job" {
  source                 = "../../../modules/pipeline/lambda_job"
  name                   = "${var.project_name}-${var.environment}-falsify-news"
  runtime                = "python3.12"
  handler                = "main.handler"
  timeout                = 900
  memory_size            = 1024
  dead_letter_target_arn = local.crawl_dlq_arn
  s3_bucket_arn          = local.data_lake_bucket_arn
  s3_object_prefixes     = [local.processed_prefix, local.dataset_prefix]
  existing_role_arn      = var.falsify_news_lambda_role_arn
  environment_variables = {
    DATA_LAKE_BUCKET = var.data_lake_bucket_name
    PROCESSED_PREFIX = local.processed_prefix
    DATASET_PREFIX   = local.dataset_prefix
    JOB_STAGE        = "falsify_news"
  }
}
