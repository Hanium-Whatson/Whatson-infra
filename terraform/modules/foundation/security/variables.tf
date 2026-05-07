variable "name" { type = string }
variable "vpc_id" { type = string }
variable "enable_lambda_redis_access" {
  type    = bool
  default = true
}
