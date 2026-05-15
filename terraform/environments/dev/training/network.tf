data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

data "aws_subnet" "training" {
  id = var.existing_subnet_id
}

locals {
  existing_public_subnet_ids = [data.aws_subnet.training.id]
}
