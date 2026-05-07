module "duplicate_guard" {
  source = "../../../modules/storage/duplicate_guard"
  name   = "${var.project_name}-${var.environment}-crawl-duplicate-guard"
}
