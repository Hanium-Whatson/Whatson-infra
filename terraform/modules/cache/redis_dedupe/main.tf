resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = replace(var.name, "_", "-")
  description                = "Redis dedupe cache for training crawler pipeline"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 1
  port                       = 6379
  parameter_group_name       = "default.redis7"
  automatic_failover_enabled = false
  multi_az_enabled           = false
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = var.security_group_ids

  tags = {
    Name = var.name
  }
}
