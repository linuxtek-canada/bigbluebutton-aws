#------------------------------------------------------------------------------
# S3 Bucket for BigBlueButton Recordings
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "recordings" {
  bucket        = "${local.name_prefix}-recordings-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.recordings_bucket_force_destroy

  tags = {
    Name    = "${local.name_prefix}-recordings"
    Purpose = "BigBlueButton recording storage"
  }
}

#------------------------------------------------------------------------------
# Block Public Access
#------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# Server-Side Encryption
#------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

#------------------------------------------------------------------------------
# Versioning
#------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  versioning_configuration {
    status = "Enabled"
  }
}

#------------------------------------------------------------------------------
# Lifecycle Rules
#------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    filter {
      prefix = "recordings/"
    }

    transition {
      days          = var.recordings_lifecycle_days
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

#------------------------------------------------------------------------------
# Bucket Logging
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "recordings_logs" {
  bucket        = "${local.name_prefix}-recordings-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.recordings_bucket_force_destroy

  tags = {
    Name    = "${local.name_prefix}-recordings-logs"
    Purpose = "S3 access logs for recordings bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "recordings_logs" {
  bucket = aws_s3_bucket.recordings_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "recordings_logs" {
  bucket = aws_s3_bucket.recordings_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "recordings_logs" {
  bucket = aws_s3_bucket.recordings_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.recordings_logs.arn}/*"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.recordings.arn
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  target_bucket = aws_s3_bucket.recordings_logs.id
  target_prefix = "access-logs/"
}
