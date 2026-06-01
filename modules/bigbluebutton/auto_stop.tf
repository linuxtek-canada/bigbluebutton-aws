#------------------------------------------------------------------------------
# EventBridge Rule to Auto-Stop Dev Instance (Cost Savings)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "auto_stop" {
  count = var.enable_auto_stop ? 1 : 0

  name                = "${local.name_prefix}-auto-stop"
  description         = "Stop EC2 instance outside business hours"
  schedule_expression = var.auto_stop_schedule

  tags = {
    Name = "${local.name_prefix}-auto-stop"
  }
}

resource "aws_cloudwatch_event_target" "auto_stop" {
  count = var.enable_auto_stop ? 1 : 0

  rule      = aws_cloudwatch_event_rule.auto_stop[0].name
  target_id = "StopInstance"
  arn       = "arn:aws:ssm:${var.aws_region}::automation-definition/AWS-StopEC2Instance"
  role_arn  = aws_iam_role.eventbridge_ssm[0].arn

  input = jsonencode({
    InstanceId = [aws_instance.bbb.id]
  })
}

#------------------------------------------------------------------------------
# EventBridge Rule to Auto-Start Dev Instance
#------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "auto_start" {
  count = var.enable_auto_stop ? 1 : 0

  name                = "${local.name_prefix}-auto-start"
  description         = "Start EC2 instance at business hours"
  schedule_expression = var.auto_start_schedule

  tags = {
    Name = "${local.name_prefix}-auto-start"
  }
}

resource "aws_cloudwatch_event_target" "auto_start" {
  count = var.enable_auto_stop ? 1 : 0

  rule      = aws_cloudwatch_event_rule.auto_start[0].name
  target_id = "StartInstance"
  arn       = "arn:aws:ssm:${var.aws_region}::automation-definition/AWS-StartEC2Instance"
  role_arn  = aws_iam_role.eventbridge_ssm[0].arn

  input = jsonencode({
    InstanceId = [aws_instance.bbb.id]
  })
}

#------------------------------------------------------------------------------
# IAM Role for EventBridge to Execute SSM Automation
#------------------------------------------------------------------------------
resource "aws_iam_role" "eventbridge_ssm" {
  count = var.enable_auto_stop ? 1 : 0

  name = "${local.name_prefix}-eventbridge-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-eventbridge-ssm-role"
  }
}

resource "aws_iam_role_policy" "eventbridge_ssm" {
  count = var.enable_auto_stop ? 1 : 0

  name = "${local.name_prefix}-eventbridge-ssm-policy"
  role = aws_iam_role.eventbridge_ssm[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:automation-definition/AWS-StopEC2Instance:*",
          "arn:aws:ssm:${var.aws_region}:*:automation-definition/AWS-StartEC2Instance:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
