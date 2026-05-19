module "network" {
  source   = "../../../modules/foundation/network"
  name     = "${var.project_name}-${var.environment}"
  vpc_cidr = "10.10.0.0/16"
}

module "security" {
  source = "../../../modules/foundation/security"
  name   = "${var.project_name}-${var.environment}"
  vpc_id = module.network.vpc_id
}

module "data_lake" {
  source           = "../../../modules/storage/s3_data_lake"
  name             = "project1-01-virg-${var.project_name}-${var.environment}-data"
  raw_prefix       = "raw"
  processed_prefix = "processed"
  dataset_prefix   = "dataset"
  artifact_prefix  = "model-artifact"
}

module "dedupe_cache" {
  source             = "../../../modules/cache/redis_dedupe"
  name               = "${var.project_name}-${var.environment}-dedupe"
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.lambda_sg_id]
}

module "crawl_dlq" {
  source = "../../../modules/pipeline/sqs_dlq"
  name   = "${var.project_name}-${var.environment}-crawl-dlq"
}

# TODO: Add Lambda jobs for crawl/preprocess/augment/train orchestration
# and attach EventBridge schedules with different cadence per job.
