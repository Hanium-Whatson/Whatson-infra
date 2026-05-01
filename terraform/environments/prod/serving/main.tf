module "network" {
  source   = "../../../modules/foundation/network"
  name     = "${var.project_name}-${var.environment}"
  vpc_cidr = "10.20.0.0/16"
}

module "security" {
  source = "../../../modules/foundation/security"
  name   = "${var.project_name}-${var.environment}"
  vpc_id = module.network.vpc_id
}

module "inference_db" {
  source             = "../../../modules/storage/rds_inference"
  name               = "${var.project_name}-${var.environment}-inference"
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.ec2_sg_id]
}

module "batch_inference" {
  source             = "../../../modules/compute/batch_inference_ec2"
  name               = "${var.project_name}-${var.environment}-batch"
  subnet_id          = module.network.private_subnet_ids[0]
  security_group_ids = [module.security.ec2_sg_id]
}

# TODO: Add EventBridge trigger for 2-3 runs/day and writer job to RDS.
