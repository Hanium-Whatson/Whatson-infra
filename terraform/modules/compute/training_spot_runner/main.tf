data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.existing_instance_profile_name
  user_data_replace_on_change = true
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"

    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent"
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y awscli
    mkdir -p /opt/whatson-training
    cat <<'ENVVARS' >/opt/whatson-training/runtime.env
    DATA_LAKE_BUCKET=${var.artifact_bucket_name}
    CHECKPOINT_PREFIX=${var.checkpoint_prefix}
    ARTIFACT_PREFIX=${var.artifact_prefix}
    %{for key, value in var.environment_variables~}
    ${key}=${value}
    %{endfor~}
    ENVVARS
    cat <<'SCRIPT' >/opt/whatson-training/run-training.sh
    #!/bin/bash
    set -a
    source /opt/whatson-training/runtime.env
    set +a
    ${var.entrypoint}
    SCRIPT
    chmod +x /opt/whatson-training/run-training.sh
    /opt/whatson-training/run-training.sh >/var/log/whatson-training.log 2>&1
  EOT

  tags = {
    Name = var.name
    Role = "training-runner"
  }
}
