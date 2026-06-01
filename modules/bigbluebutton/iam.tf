#------------------------------------------------------------------------------
# IAM Role for EC2 Instance
#------------------------------------------------------------------------------
resource "aws_iam_role" "bbb_instance" {
  name = "${local.name_prefix}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-instance-role"
  }
}

#------------------------------------------------------------------------------
# IAM Policy for S3 Recordings Access
#------------------------------------------------------------------------------
resource "aws_iam_policy" "bbb_s3_access" {
  name        = "${local.name_prefix}-s3-recordings-policy"
  description = "Allow BigBlueButton to upload recordings to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.recordings.arn
      },
      {
        Sid    = "AllowObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.recordings.arn}/*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-s3-recordings-policy"
  }
}

resource "aws_iam_role_policy_attachment" "bbb_s3_access" {
  role       = aws_iam_role.bbb_instance.name
  policy_arn = aws_iam_policy.bbb_s3_access.arn
}

#------------------------------------------------------------------------------
# SSM Managed Instance Core (for Systems Manager access)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.bbb_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#------------------------------------------------------------------------------
# Instance Profile
#------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "bbb_instance" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.bbb_instance.name

  tags = {
    Name = "${local.name_prefix}-instance-profile"
  }
}
