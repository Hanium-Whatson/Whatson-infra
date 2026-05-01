resource "aws_security_group" "lambda" {
  name        = "${var.name}-lambda"
  description = "Security group for training pipeline Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-lambda"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis"
  description = "Security group for training Redis cache"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-redis"
  }
}

resource "aws_security_group_rule" "redis_from_lambda" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow Lambda functions to reach Redis"
}

resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2"
  description = "Security group for training compute runners"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ec2"
  }
}
