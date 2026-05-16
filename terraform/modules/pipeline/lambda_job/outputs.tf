output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "role_arn" {
  value = var.existing_role_arn
}

output "log_group_name" {
  value = var.manage_log_group ? aws_cloudwatch_log_group.this[0].name : "/aws/lambda/${var.name}"
}
