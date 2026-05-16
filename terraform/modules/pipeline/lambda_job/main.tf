terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
}

locals {
  source_dir = var.source_dir != null ? var.source_dir : "${path.module}/src/python"
  use_vpc    = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0
  s3_arns = var.s3_bucket_arn == null ? [] : concat(
    [var.s3_bucket_arn],
    [for prefix in var.s3_object_prefixes : "${var.s3_bucket_arn}/${prefix}*"],
  )
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = "${path.module}/build/${var.name}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.manage_log_group ? 1 : 0
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "this" {
  function_name    = var.name
  role             = var.existing_role_arn
  runtime          = var.runtime
  handler          = var.handler
  timeout          = var.timeout
  memory_size      = var.memory_size
  filename         = data.archive_file.package.output_path
  source_code_hash = data.archive_file.package.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = local.use_vpc ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dead_letter_config {
    target_arn = var.dead_letter_target_arn
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_lambda_function_event_invoke_config" "this" {
  function_name          = aws_lambda_function.this.function_name
  maximum_retry_attempts = 2
}
