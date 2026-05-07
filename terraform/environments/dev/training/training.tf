module "training_runner" {
  source               = "../../../modules/compute/training_spot_runner"
  name                 = "${var.project_name}-${var.environment}-training-runner"
  subnet_id            = module.network.public_subnet_ids[0]
  security_group_ids   = [module.security.ec2_sg_id]
  instance_type        = var.training_instance_type
  ami_id               = var.training_ami_id
  artifact_bucket_name = module.data_lake.bucket_name
  artifact_bucket_arn  = module.data_lake.bucket_arn
  checkpoint_prefix    = local.checkpoint_prefix
  artifact_prefix      = local.artifact_prefix
  entrypoint           = var.training_entrypoint
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
