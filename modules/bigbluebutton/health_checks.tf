#------------------------------------------------------------------------------
# Route 53 Health Check
#------------------------------------------------------------------------------
resource "aws_route53_health_check" "bbb" {
  count = var.domain_name != "" && var.enable_health_check ? 1 : 0

  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/bigbluebutton/api"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${local.name_prefix}-health-check"
  }
}

#------------------------------------------------------------------------------
# CloudWatch Alarm for Health Check
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count = var.domain_name != "" && var.enable_health_check ? 1 : 0

  alarm_name          = "${local.name_prefix}-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "BigBlueButton health check failed"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.bbb[0].id
  }

  tags = {
    Name = "${local.name_prefix}-health-check-alarm"
  }
}
