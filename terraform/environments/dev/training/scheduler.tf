module "crawl_schedule" {
  source              = "../../../modules/pipeline/eventbridge_scheduler"
  name                = "${var.project_name}-${var.environment}-crawl-schedule"
  schedule_expression = var.crawl_schedule_expression
  target_arn          = module.crawl_job.function_arn
}

module "preprocess_schedule" {
  source              = "../../../modules/pipeline/eventbridge_scheduler"
  name                = "${var.project_name}-${var.environment}-preprocess-schedule"
  schedule_expression = var.preprocess_schedule_expression
  target_arn          = module.preprocess_job.function_arn
}

module "augment_schedule" {
  source              = "../../../modules/pipeline/eventbridge_scheduler"
  name                = "${var.project_name}-${var.environment}-augment-schedule"
  schedule_expression = var.augment_schedule_expression
  target_arn          = module.augment_job.function_arn
}
