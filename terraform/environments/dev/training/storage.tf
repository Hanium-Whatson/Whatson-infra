data "aws_s3_bucket" "data_lake" {
  bucket = var.data_lake_bucket_name
}

data "aws_dynamodb_table" "duplicate_guard" {
  name = local.duplicate_guard_table_name
}

data "aws_sqs_queue" "crawl_dlq" {
  name = local.crawl_dlq_name
}
