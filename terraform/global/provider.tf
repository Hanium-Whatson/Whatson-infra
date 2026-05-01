variable "aws_region" {
  type        = string
  description = "AWS region for shared resources"
}

provider "aws" {
  region = var.aws_region
}
