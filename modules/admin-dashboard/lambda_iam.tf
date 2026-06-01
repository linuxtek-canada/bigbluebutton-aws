#------------------------------------------------------------------------------
# Lambda Execution Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_exec" {
  name = "${local.name_prefix}-lambda-exec-role"

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

#------------------------------------------------------------------------------
# Lambda Basic Execution (CloudWatch Logs)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#------------------------------------------------------------------------------
# EC2 Control Policy
#------------------------------------------------------------------------------
resource "aws_iam_policy" "ec2_control" {
  name        = "${local.name_prefix}-ec2-control-policy"
  description = "Allow Lambda to start/stop the BigBlueButton instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeInstances"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Sid    = "ControlInstance"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${var.bbb_instance_id}"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_control" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.ec2_control.arn
}

#------------------------------------------------------------------------------
# S3 Recordings Access Policy
#------------------------------------------------------------------------------
resource "aws_iam_policy" "s3_recordings" {
  name        = "${local.name_prefix}-s3-recordings-policy"
  description = "Allow Lambda to list and access recordings"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = var.recordings_bucket_arn
      },
      {
        Sid    = "GetObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAttributes"
        ]
        Resource = "${var.recordings_bucket_arn}/*"
      },
      {
        Sid    = "GeneratePresignedUrls"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.recordings_bucket_arn}/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_recordings" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.s3_recordings.arn
}
