#------------------------------------------------------------------------------
# API Gateway Account Settings (CloudWatch Logging)
#------------------------------------------------------------------------------
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.name_prefix}-api-gw-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

#------------------------------------------------------------------------------
# API Gateway REST API
#------------------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "admin" {
  name        = "${local.name_prefix}-admin-api"
  description = "Admin API for BigBlueButton management"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Cognito Authorizer
#------------------------------------------------------------------------------
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.name_prefix}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.admin.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = [aws_cognito_user_pool.admin.arn]
}

#------------------------------------------------------------------------------
# EC2 Resource
#------------------------------------------------------------------------------
resource "aws_api_gateway_resource" "ec2" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  parent_id   = aws_api_gateway_rest_api.admin.root_resource_id
  path_part   = "ec2"
}

resource "aws_api_gateway_method" "ec2_post" {
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  resource_id   = aws_api_gateway_resource.ec2.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "ec2_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.admin.id
  resource_id             = aws_api_gateway_resource.ec2.id
  http_method             = aws_api_gateway_method.ec2_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ec2_control.invoke_arn
}

resource "aws_api_gateway_method" "ec2_get" {
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  resource_id   = aws_api_gateway_resource.ec2.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "ec2_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.admin.id
  resource_id             = aws_api_gateway_resource.ec2.id
  http_method             = aws_api_gateway_method.ec2_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ec2_control.invoke_arn
}

#------------------------------------------------------------------------------
# Recordings Resource
#------------------------------------------------------------------------------
resource "aws_api_gateway_resource" "recordings" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  parent_id   = aws_api_gateway_rest_api.admin.root_resource_id
  path_part   = "recordings"
}

resource "aws_api_gateway_method" "recordings_get" {
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  resource_id   = aws_api_gateway_resource.recordings.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "recordings_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.admin.id
  resource_id             = aws_api_gateway_resource.recordings.id
  http_method             = aws_api_gateway_method.recordings_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.s3_recordings.invoke_arn
}

resource "aws_api_gateway_method" "recordings_post" {
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  resource_id   = aws_api_gateway_resource.recordings.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "recordings_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.admin.id
  resource_id             = aws_api_gateway_resource.recordings.id
  http_method             = aws_api_gateway_method.recordings_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.s3_recordings.invoke_arn
}

#------------------------------------------------------------------------------
# CORS Configuration
#------------------------------------------------------------------------------
resource "aws_api_gateway_method" "ec2_options" {
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  resource_id   = aws_api_gateway_resource.ec2.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ec2_options" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.ec2_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "ec2_options" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.ec2_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "ec2_options" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.ec2_options.http_method
  status_code = aws_api_gateway_method_response.ec2_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "recordings_options" {
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  resource_id   = aws_api_gateway_resource.recordings.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "recordings_options" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  resource_id = aws_api_gateway_resource.recordings.id
  http_method = aws_api_gateway_method.recordings_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "recordings_options" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  resource_id = aws_api_gateway_resource.recordings.id
  http_method = aws_api_gateway_method.recordings_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "recordings_options" {
  rest_api_id = aws_api_gateway_rest_api.admin.id
  resource_id = aws_api_gateway_resource.recordings.id
  http_method = aws_api_gateway_method.recordings_options.http_method
  status_code = aws_api_gateway_method_response.recordings_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

#------------------------------------------------------------------------------
# API Gateway Deployment
#------------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "admin" {
  rest_api_id = aws_api_gateway_rest_api.admin.id

  depends_on = [
    aws_api_gateway_integration.ec2_lambda,
    aws_api_gateway_integration.ec2_get_lambda,
    aws_api_gateway_integration.recordings_lambda,
    aws_api_gateway_integration.recordings_post_lambda,
    aws_api_gateway_integration.ec2_options,
    aws_api_gateway_integration.recordings_options
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.ec2.id,
      aws_api_gateway_resource.recordings.id,
      aws_api_gateway_method.ec2_post.id,
      aws_api_gateway_method.ec2_get.id,
      aws_api_gateway_method.recordings_get.id,
      aws_api_gateway_method.recordings_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "admin" {
  deployment_id = aws_api_gateway_deployment.admin.id
  rest_api_id   = aws_api_gateway_rest_api.admin.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}-admin-api"
  retention_in_days = 30

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Lambda Permissions for API Gateway
#------------------------------------------------------------------------------
resource "aws_lambda_permission" "ec2_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_control.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.admin.execution_arn}/*/*"
}

resource "aws_lambda_permission" "recordings_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_recordings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.admin.execution_arn}/*/*"
}
