output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2.id
}
