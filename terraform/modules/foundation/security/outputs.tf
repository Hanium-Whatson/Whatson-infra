output "lambda_sg_id" {
  value = var.enable_lambda_redis_access ? aws_security_group.lambda[0].id : null
}

output "redis_sg_id" {
  value = var.enable_lambda_redis_access ? aws_security_group.redis[0].id : null
}

output "ec2_sg_id" {
  value = aws_security_group.ec2.id
}
