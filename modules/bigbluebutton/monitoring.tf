#------------------------------------------------------------------------------
# CloudWatch Alarms for BigBlueButton
#------------------------------------------------------------------------------

# EC2 Status Check Failed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "${local.name_prefix}-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance status check failed"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.bbb.id
  }

  tags = {
    Name = "${local.name_prefix}-ec2-status-check"
  }
}

# EC2 CPU Utilization High
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization above 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.bbb.id
  }

  tags = {
    Name = "${local.name_prefix}-ec2-cpu-high"
  }
}

# EC2 CPU Utilization Critical
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_critical" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 95
  alarm_description   = "EC2 CPU utilization above 95% - CRITICAL"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.bbb.id
  }

  tags = {
    Name = "${local.name_prefix}-ec2-cpu-critical"
  }
}

# EBS Volume Queue Length
resource "aws_cloudwatch_metric_alarm" "ebs_queue_length" {
  alarm_name          = "${local.name_prefix}-ebs-queue-length"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "VolumeQueueLength"
  namespace           = "AWS/EBS"
  period              = 300
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "EBS volume queue length high - possible I/O bottleneck"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    VolumeId = aws_instance.bbb.root_block_device[0].volume_id
  }

  tags = {
    Name = "${local.name_prefix}-ebs-queue-length"
  }
}

# Network In High
resource "aws_cloudwatch_metric_alarm" "network_in_high" {
  alarm_name          = "${local.name_prefix}-network-in-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 500000000 # 500 MB/5min = ~13 Mbps sustained
  alarm_description   = "Network ingress traffic unusually high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.bbb.id
  }

  tags = {
    Name = "${local.name_prefix}-network-in-high"
  }
}
