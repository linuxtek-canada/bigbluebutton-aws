#------------------------------------------------------------------------------
# SNS Topic for Budget Alerts
#------------------------------------------------------------------------------
resource "aws_sns_topic" "budget_alerts" {
  name = "${local.name_prefix}-budget-alerts"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_policy" "budget_alerts" {
  arn = aws_sns_topic.budget_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBudgetsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.budget_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# AWS Budget - Alert at $100
#------------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly_alert" {
  name         = "${local.name_prefix}-monthly-alert"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_alert_threshold)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$${var.project_name}"]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# AWS Budget - Hard Limit at $200 (triggers Lambda)
#------------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly_limit" {
  name         = "${local.name_prefix}-monthly-limit"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$${var.project_name}"]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Lambda Function to Stop EC2 Instances on Budget Breach
#------------------------------------------------------------------------------
data "archive_file" "budget_enforcer" {
  count = var.enable_auto_stop ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda/budget_enforcer.zip"

  source {
    content  = <<-EOF
      import boto3
      import os
      import json

      ec2 = boto3.client('ec2')
      sns = boto3.client('sns')

      def lambda_handler(event, context):
          instance_ids = os.environ.get('INSTANCE_IDS', '').split(',')
          sns_topic = os.environ.get('SNS_TOPIC_ARN', '')
          project = os.environ.get('PROJECT_NAME', 'unknown')

          if not instance_ids or instance_ids == ['']:
              print("No instance IDs configured")
              return {'statusCode': 200, 'body': 'No instances to stop'}

          print(f"Budget limit reached! Stopping instances: {instance_ids}")

          try:
              # Stop the instances
              response = ec2.stop_instances(InstanceIds=instance_ids)
              stopped = [i['InstanceId'] for i in response['StoppingInstances']]

              message = f"""
      BUDGET LIMIT REACHED - RESOURCES STOPPED

      Project: {project}
      Action: EC2 instances have been automatically stopped

      Stopped Instances:
      {json.dumps(stopped, indent=2)}

      To resume service, manually start the instances after reviewing costs.
              """

              # Send notification
              if sns_topic:
                  sns.publish(
                      TopicArn=sns_topic,
                      Subject=f'[CRITICAL] Budget Limit Reached - {project}',
                      Message=message
                  )

              return {
                  'statusCode': 200,
                  'body': json.dumps({'stopped_instances': stopped})
              }

          except Exception as e:
              print(f"Error stopping instances: {str(e)}")
              return {
                  'statusCode': 500,
                  'body': json.dumps({'error': str(e)})
              }
    EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "budget_enforcer" {
  count = var.enable_auto_stop ? 1 : 0

  function_name = "${local.name_prefix}-budget-enforcer"
  role          = aws_iam_role.budget_enforcer[0].arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 128

  filename         = data.archive_file.budget_enforcer[0].output_path
  source_code_hash = data.archive_file.budget_enforcer[0].output_base64sha256

  environment {
    variables = {
      INSTANCE_IDS  = var.ec2_instance_id
      SNS_TOPIC_ARN = aws_sns_topic.budget_alerts.arn
      PROJECT_NAME  = var.project_name
    }
  }

  tags = local.common_tags
}

resource "aws_iam_role" "budget_enforcer" {
  count = var.enable_auto_stop ? 1 : 0

  name = "${local.name_prefix}-budget-enforcer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "budget_enforcer" {
  count = var.enable_auto_stop ? 1 : 0

  name = "${local.name_prefix}-budget-enforcer-policy"
  role = aws_iam_role.budget_enforcer[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.budget_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "budget_enforcer" {
  count = var.enable_auto_stop ? 1 : 0

  name              = "/aws/lambda/${aws_lambda_function.budget_enforcer[0].function_name}"
  retention_in_days = 30

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# SNS Subscription to Trigger Lambda
#------------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "budget_enforcer" {
  count = var.enable_auto_stop ? 1 : 0

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.budget_enforcer[0].arn

  filter_policy = jsonencode({
    budgetName = ["${local.name_prefix}-monthly-limit"]
  })
}

resource "aws_lambda_permission" "budget_sns" {
  count = var.enable_auto_stop ? 1 : 0

  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.budget_enforcer[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.budget_alerts.arn
}
