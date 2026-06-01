#------------------------------------------------------------------------------
# GuardDuty Detector
#------------------------------------------------------------------------------
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-guardduty"
  })
}

#------------------------------------------------------------------------------
# GuardDuty SNS Notifications
#------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count = var.enable_guardduty && var.enable_sns_notifications ? 1 : 0

  name        = "${local.name_prefix}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        { numeric = [">=", 4] }
      ]
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count = var.enable_guardduty && var.enable_sns_notifications ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_findings[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      finding     = "$.detail.type"
      description = "$.detail.description"
      region      = "$.region"
      account     = "$.account"
    }
    input_template = "\"GuardDuty Finding: <finding> (Severity: <severity>) in <region>. <description>\""
  }
}
