module "dedupe_cache" {
  source             = "../../../modules/cache/redis_dedupe"
  name               = "${var.project_name}-${var.environment}-dedupe"
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.redis_sg_id]
}
