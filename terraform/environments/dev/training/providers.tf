terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {}
}

variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "existing_vpc_id" { type = string }
variable "existing_subnet_id" { type = string }
variable "existing_security_group_ids" { type = list(string) }
variable "data_lake_bucket_name" { type = string }
variable "duplicate_guard_table_name" {
  type    = string
  default = ""
}
variable "crawl_dlq_name" {
  type    = string
  default = ""
}
variable "crawl_dlq_arn" {
  type    = string
  default = ""
}
variable "crawl_schedule_expression" {
  type    = string
  default = "rate(6 hours)"
}
variable "training_instance_type" {
  type    = string
  default = "g4dn.xlarge"
}
variable "training_ami_id" {
  type    = string
  default = ""
}
variable "training_entrypoint" {
  type = string
}
variable "training_environment_variables" {
  type    = map(string)
  default = {}
}
variable "training_runner_instance_profile_name" {
  type = string
}
variable "crawl_lambda_role_arn" {
  type = string
}
variable "preprocess_lambda_role_arn" {
  type = string
}
variable "falsify_news_lambda_role_arn" {
  type = string
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Stack       = "training"
    }
  }
}
