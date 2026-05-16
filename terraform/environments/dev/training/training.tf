module "training_runner" {
  source                         = "../../../modules/compute/training_spot_runner"
  name                           = "${var.project_name}-${var.environment}-training-runner"
  subnet_id                      = data.aws_subnet.training.id
  security_group_ids             = var.existing_security_group_ids
  instance_type                  = var.training_instance_type
  ami_id                         = var.training_ami_id
  artifact_bucket_name           = data.aws_s3_bucket.data_lake.bucket
  artifact_bucket_arn            = data.aws_s3_bucket.data_lake.arn
  checkpoint_prefix              = local.checkpoint_prefix
  artifact_prefix                = local.artifact_prefix
  entrypoint                     = var.training_entrypoint
  existing_instance_profile_name = var.training_runner_instance_profile_name
  environment_variables = merge(
    {
      PROJECT_NAME      = var.project_name
      ENVIRONMENT       = var.environment
      DATASET_PREFIX    = local.dataset_prefix
      CHECKPOINT_PREFIX = local.checkpoint_prefix
      MODEL_ARTIFACTS   = local.artifact_prefix
      RUNNER_TARGET     = "ec2-spot"
      FUTURE_RUNTIME    = "runpod"
    },
    var.training_environment_variables,
  )
}
