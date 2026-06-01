#------------------------------------------------------------------------------
# Lambda Function - EC2 Control
#------------------------------------------------------------------------------
data "archive_file" "ec2_control" {
  type        = "zip"
  output_path = "${path.module}/lambda/ec2_control.zip"

  source {
    content  = <<-EOF
      import json
      import boto3
      import os

      ec2 = boto3.client('ec2')
      INSTANCE_ID = os.environ['INSTANCE_ID']

      def lambda_handler(event, context):
          try:
              action = event.get('action', 'status')

              if action == 'start':
                  ec2.start_instances(InstanceIds=[INSTANCE_ID])
                  return {
                      'statusCode': 200,
                      'body': json.dumps({'message': 'Instance starting', 'action': 'start'})
                  }
              elif action == 'stop':
                  ec2.stop_instances(InstanceIds=[INSTANCE_ID])
                  return {
                      'statusCode': 200,
                      'body': json.dumps({'message': 'Instance stopping', 'action': 'stop'})
                  }
              elif action == 'status':
                  response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
                  state = response['Reservations'][0]['Instances'][0]['State']['Name']
                  return {
                      'statusCode': 200,
                      'body': json.dumps({'status': state, 'instanceId': INSTANCE_ID})
                  }
              else:
                  return {
                      'statusCode': 400,
                      'body': json.dumps({'error': 'Invalid action'})
                  }
          except Exception as e:
              return {
                  'statusCode': 500,
                  'body': json.dumps({'error': str(e)})
              }
    EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "ec2_control" {
  function_name = "${local.name_prefix}-ec2-control"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 128

  filename         = data.archive_file.ec2_control.output_path
  source_code_hash = data.archive_file.ec2_control.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = var.bbb_instance_id
    }
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Lambda Function - S3 Recordings
#------------------------------------------------------------------------------
data "archive_file" "s3_recordings" {
  type        = "zip"
  output_path = "${path.module}/lambda/s3_recordings.zip"

  source {
    content  = <<-EOF
      import json
      import boto3
      import os
      from datetime import datetime

      s3 = boto3.client('s3')
      BUCKET_NAME = os.environ['BUCKET_NAME']

      def lambda_handler(event, context):
          try:
              action = event.get('action', 'list')

              if action == 'list':
                  prefix = event.get('prefix', '')
                  paginator = s3.get_paginator('list_objects_v2')

                  files = []
                  for page in paginator.paginate(Bucket=BUCKET_NAME, Prefix=prefix, MaxKeys=100):
                      for obj in page.get('Contents', []):
                          files.append({
                              'key': obj['Key'],
                              'size': obj['Size'],
                              'lastModified': obj['LastModified'].isoformat()
                          })

                  return {
                      'statusCode': 200,
                      'body': json.dumps({'files': files, 'bucket': BUCKET_NAME})
                  }

              elif action == 'download':
                  key = event.get('key')
                  if not key:
                      return {
                          'statusCode': 400,
                          'body': json.dumps({'error': 'Key is required'})
                      }

                  url = s3.generate_presigned_url(
                      'get_object',
                      Params={'Bucket': BUCKET_NAME, 'Key': key},
                      ExpiresIn=3600
                  )

                  return {
                      'statusCode': 200,
                      'body': json.dumps({'downloadUrl': url, 'expiresIn': 3600})
                  }

              else:
                  return {
                      'statusCode': 400,
                      'body': json.dumps({'error': 'Invalid action'})
                  }

          except Exception as e:
              return {
                  'statusCode': 500,
                  'body': json.dumps({'error': str(e)})
              }
    EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "s3_recordings" {
  function_name = "${local.name_prefix}-s3-recordings"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.s3_recordings.output_path
  source_code_hash = data.archive_file.s3_recordings.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = var.recordings_bucket_name
    }
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# CloudWatch Log Groups
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ec2_control" {
  name              = "/aws/lambda/${aws_lambda_function.ec2_control.function_name}"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "s3_recordings" {
  name              = "/aws/lambda/${aws_lambda_function.s3_recordings.function_name}"
  retention_in_days = 30

  tags = local.common_tags
}
