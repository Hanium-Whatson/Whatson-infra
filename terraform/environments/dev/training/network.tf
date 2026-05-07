module "network" {
  source                 = "../../../modules/foundation/network"
  name                   = "${var.project_name}-${var.environment}-training"
  vpc_cidr               = var.vpc_cidr
  enable_private_network = false
}

module "security" {
  source                     = "../../../modules/foundation/security"
  name                       = "${var.project_name}-${var.environment}-training"
  vpc_id                     = module.network.vpc_id
  enable_lambda_redis_access = false
}
