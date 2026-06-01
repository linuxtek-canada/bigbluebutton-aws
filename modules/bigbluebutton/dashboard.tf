#------------------------------------------------------------------------------
# CloudWatch Dashboard
#------------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# BigBlueButton Infrastructure Dashboard - ${var.environment}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.bbb.id, { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              { value = 80, label = "Warning", color = "#ff7f0e" },
              { value = 95, label = "Critical", color = "#d62728" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Network Traffic"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.bbb.id, { stat = "Sum", period = 300, label = "In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.bbb.id, { stat = "Sum", period = 300, label = "Out" }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "EC2 Status"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.bbb.id, { stat = "Maximum", period = 60 }],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", aws_instance.bbb.id, { stat = "Maximum", period = 60 }],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", aws_instance.bbb.id, { stat = "Maximum", period = 60 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "EBS Volume IOPS"
          region = var.aws_region
          metrics = [
            ["AWS/EBS", "VolumeReadOps", "VolumeId", aws_instance.bbb.root_block_device[0].volume_id, { stat = "Sum", period = 300, label = "Read" }],
            ["AWS/EBS", "VolumeWriteOps", "VolumeId", aws_instance.bbb.root_block_device[0].volume_id, { stat = "Sum", period = 300, label = "Write" }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "EBS Queue Length"
          region = var.aws_region
          metrics = [
            ["AWS/EBS", "VolumeQueueLength", "VolumeId", aws_instance.bbb.root_block_device[0].volume_id, { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
          annotations = {
            horizontal = [
              { value = 10, label = "Warning", color = "#ff7f0e" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "S3 Requests"
          region = var.aws_region
          metrics = [
            ["AWS/S3", "AllRequests", "BucketName", aws_s3_bucket.recordings.id, "FilterId", "AllRequests", { stat = "Sum", period = 3600 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 13
        width  = 24
        height = 3
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.ec2_status_check.arn,
            aws_cloudwatch_metric_alarm.ec2_cpu_high.arn,
            aws_cloudwatch_metric_alarm.ec2_cpu_critical.arn,
            aws_cloudwatch_metric_alarm.ebs_queue_length.arn
          ]
        }
      }
    ]
  })
}
