module "crawl_schedule" {
  source              = "../../../modules/pipeline/eventbridge_scheduler"
  name                = "${var.project_name}-${var.environment}-crawl-schedule"
  schedule_expression = var.crawl_schedule_expression
  target_arn          = module.crawl_job.function_arn
}
