module "data_lake" {
  source           = "../../../modules/storage/s3_data_lake"
  name             = var.data_lake_bucket_name
  raw_prefix       = local.raw_prefix
  processed_prefix = local.processed_prefix
  dataset_prefix   = local.dataset_prefix
  artifact_prefix  = local.artifact_prefix
}
