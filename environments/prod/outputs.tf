#------------------------------------------------------------------------------
# VPC Outputs
#------------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.bigbluebutton.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.bigbluebutton.public_subnet_id
}

#------------------------------------------------------------------------------
# EC2 Outputs
#------------------------------------------------------------------------------
output "instance_id" {
  description = "ID of the BigBlueButton EC2 instance"
  value       = module.bigbluebutton.instance_id
}

output "instance_public_ip" {
  description = "Elastic IP address of the BigBlueButton instance"
  value       = module.bigbluebutton.instance_public_ip
}

#------------------------------------------------------------------------------
# S3 Outputs
#------------------------------------------------------------------------------
output "recordings_bucket_name" {
  description = "Name of the S3 bucket for recordings"
  value       = module.bigbluebutton.recordings_bucket_name
}

output "recordings_bucket_arn" {
  description = "ARN of the S3 bucket for recordings"
  value       = module.bigbluebutton.recordings_bucket_arn
}

#------------------------------------------------------------------------------
# Connection Information
#------------------------------------------------------------------------------
output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = module.bigbluebutton.ssh_connection_command
}

output "bbb_install_command" {
  description = "Command to install BigBlueButton"
  value       = module.bigbluebutton.bbb_install_command
}

#------------------------------------------------------------------------------
# Admin Dashboard Outputs
#------------------------------------------------------------------------------
output "admin_dashboard_url" {
  description = "URL of the admin dashboard"
  value       = module.admin_dashboard.admin_dashboard_url
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = module.admin_dashboard.cognito_user_pool_id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.admin_dashboard.api_gateway_endpoint
}

#------------------------------------------------------------------------------
# Monitoring Outputs
#------------------------------------------------------------------------------
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.bigbluebutton.cloudwatch_dashboard_url
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.bigbluebutton.sns_topic_arn
}

#------------------------------------------------------------------------------
# Backup Outputs
#------------------------------------------------------------------------------
output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault"
  value       = module.bigbluebutton.backup_vault_arn
}

#------------------------------------------------------------------------------
# KMS Outputs
#------------------------------------------------------------------------------
output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = module.bigbluebutton.kms_key_arn
}

#------------------------------------------------------------------------------
# Security Outputs
#------------------------------------------------------------------------------
output "cloudtrail_bucket" {
  description = "S3 bucket name for CloudTrail logs"
  value       = module.security.cloudtrail_bucket_name
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.security.guardduty_detector_id
}

#------------------------------------------------------------------------------
# Cost Management Outputs
#------------------------------------------------------------------------------
output "budget_alerts_topic_arn" {
  description = "ARN of the SNS topic for budget alerts"
  value       = module.cost.budget_alert_sns_topic_arn
}

#------------------------------------------------------------------------------
# WAF Outputs
#------------------------------------------------------------------------------
output "waf_web_acl_arn" {
  description = "ARN of the WAF WebACL"
  value       = module.admin_dashboard.waf_web_acl_arn
}

#------------------------------------------------------------------------------
# Health Check Outputs
#------------------------------------------------------------------------------
output "health_check_id" {
  description = "ID of the Route 53 health check"
  value       = module.bigbluebutton.health_check_id
}
