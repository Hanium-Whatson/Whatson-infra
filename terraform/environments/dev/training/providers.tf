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
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "data_lake_bucket_name" { type = string }
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
