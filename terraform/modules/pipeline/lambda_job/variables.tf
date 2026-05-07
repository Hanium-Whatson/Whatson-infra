variable "name" { type = string }
variable "runtime" { type = string }
variable "handler" { type = string }
variable "timeout" { type = number }
variable "memory_size" { type = number }
variable "environment_variables" { type = map(string) }
variable "dead_letter_target_arn" { type = string }
variable "source_dir" {
  type    = string
  default = null
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "log_retention_in_days" {
  type    = number
  default = 14
}
variable "s3_bucket_arn" {
  type    = string
  default = null
}
variable "s3_object_prefixes" {
  type    = list(string)
  default = []
}

variable "dynamodb_table_arn" {
  type    = string
  default = null
}
variable "lambda_invoke_function_arns" {
  type    = list(string)
  default = []
}
