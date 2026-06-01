#------------------------------------------------------------------------------
# CloudFront Outputs
#------------------------------------------------------------------------------
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.admin.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.admin.domain_name
}

output "admin_dashboard_url" {
  description = "URL of the admin dashboard"
  value       = "https://${aws_cloudfront_distribution.admin.domain_name}"
}

#------------------------------------------------------------------------------
# Cognito Outputs
#------------------------------------------------------------------------------
output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = aws_cognito_user_pool.admin.id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito user pool client"
  value       = aws_cognito_user_pool_client.admin.id
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = "https://${aws_cognito_user_pool_domain.admin.domain}.auth.${var.aws_region}.amazoncognito.com"
}

#------------------------------------------------------------------------------
# API Gateway Outputs
#------------------------------------------------------------------------------
output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.admin.invoke_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.admin.id
}

#------------------------------------------------------------------------------
# S3 Outputs
#------------------------------------------------------------------------------
output "website_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.id
}

output "website_bucket_arn" {
  description = "ARN of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.arn
}

#------------------------------------------------------------------------------
# Lambda Outputs
#------------------------------------------------------------------------------
output "ec2_control_lambda_arn" {
  description = "ARN of the EC2 control Lambda function"
  value       = aws_lambda_function.ec2_control.arn
}

output "s3_recordings_lambda_arn" {
  description = "ARN of the S3 recordings Lambda function"
  value       = aws_lambda_function.s3_recordings.arn
}

#------------------------------------------------------------------------------
# WAF Outputs
#------------------------------------------------------------------------------
output "waf_web_acl_arn" {
  description = "ARN of the WAF WebACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF WebACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}
