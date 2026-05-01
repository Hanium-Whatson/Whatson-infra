variable "name" { type = string }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "instance_type" { type = string }
variable "entrypoint" { type = string }
variable "environment_variables" { type = map(string) }
variable "artifact_bucket_name" { type = string }
variable "artifact_bucket_arn" { type = string }
variable "checkpoint_prefix" { type = string }
variable "artifact_prefix" { type = string }
variable "ami_id" {
  type    = string
  default = ""
}
