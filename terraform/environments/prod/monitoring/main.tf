module "cloudwatch" {
  source              = "../../../modules/observability/cloudwatch"
  name                = "${var.project_name}-${var.environment}"
  alarm_sns_topic_arn = "arn:aws:sns:ap-northeast-2:123456789012:discord-alerts"
}

module "grafana" {
  source = "../../../modules/observability/grafana"
  name   = "${var.project_name}-${var.environment}"
}
