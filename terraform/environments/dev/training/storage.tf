data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  data_lake_bucket_arn       = "arn:${data.aws_partition.current.partition}:s3:::${var.data_lake_bucket_name}"
  duplicate_guard_table_arn  = "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${local.duplicate_guard_table_name}"
  crawl_dlq_arn              = var.crawl_dlq_arn != "" ? var.crawl_dlq_arn : "arn:${data.aws_partition.current.partition}:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${local.crawl_dlq_name}"
}
