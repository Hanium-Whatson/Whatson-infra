locals {
  raw_prefix                 = "raw"
  processed_prefix           = "processed"
  dataset_prefix             = "dataset"
  artifact_prefix            = "model-artifact"
  checkpoint_prefix          = "${local.artifact_prefix}/checkpoints"
  duplicate_guard_table_name = var.duplicate_guard_table_name != "" ? var.duplicate_guard_table_name : "${var.project_name}-${var.environment}-crawl-duplicate-guard"
  crawl_dlq_name             = var.crawl_dlq_name != "" ? var.crawl_dlq_name : "${var.project_name}-${var.environment}-crawl-dlq"
}
