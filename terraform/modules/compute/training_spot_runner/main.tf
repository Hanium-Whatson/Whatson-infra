data "aws_ami" "amazon_l1inux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "inline" {
  statement {
    sid = "S3Artifacts"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      var.artifact_bucket_arn,
      "${var.artifact_bucket_arn}/${var.checkpoint_prefix}*",
      "${var.artifact_bucket_arn}/${var.artifact_prefix}*",
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.inline.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-profile"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = aws_iam_instance_profile.this.name
  user_data_replace_on_change = true
  associate_public_ip_address = false

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
    dnf install -y awscli
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
