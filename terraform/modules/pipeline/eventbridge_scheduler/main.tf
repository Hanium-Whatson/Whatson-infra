resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  description         = "Schedule for ${var.name}"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "${var.name}-target"
  arn       = var.target_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = replace("${var.name}-invoke", "-", "")
  action        = "lambda:InvokeFunction"
  function_name = var.target_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}
