#------------------------------------------------------------------------------
# VPC Outputs
#------------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

#------------------------------------------------------------------------------
# EC2 Outputs
#------------------------------------------------------------------------------
output "instance_id" {
  description = "ID of the BigBlueButton EC2 instance"
  value       = aws_instance.bbb.id
}

output "instance_private_ip" {
  description = "Private IP address of the BigBlueButton instance"
  value       = aws_instance.bbb.private_ip
}

output "instance_public_ip" {
  description = "Elastic IP address of the BigBlueButton instance"
  value       = aws_eip.bbb.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the Elastic IP"
  value       = aws_eip.bbb.public_dns
}

#------------------------------------------------------------------------------
# S3 Outputs
#------------------------------------------------------------------------------
output "recordings_bucket_name" {
  description = "Name of the S3 bucket for recordings"
  value       = aws_s3_bucket.recordings.id
}

output "recordings_bucket_arn" {
  description = "ARN of the S3 bucket for recordings"
  value       = aws_s3_bucket.recordings.arn
}

output "recordings_bucket_domain_name" {
  description = "Domain name of the recordings S3 bucket"
  value       = aws_s3_bucket.recordings.bucket_regional_domain_name
}

#------------------------------------------------------------------------------
# Security Group Outputs
#------------------------------------------------------------------------------
output "security_group_id" {
  description = "ID of the BigBlueButton security group"
  value       = aws_security_group.bbb.id
}

#------------------------------------------------------------------------------
# IAM Outputs
#------------------------------------------------------------------------------
output "instance_role_arn" {
  description = "ARN of the EC2 instance IAM role"
  value       = aws_iam_role.bbb_instance.arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.bbb_instance.name
}

#------------------------------------------------------------------------------
# Connection Information
#------------------------------------------------------------------------------
output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.bbb.public_ip}"
}

output "bbb_install_command" {
  description = "Command to install BigBlueButton after SSH"
  value       = "wget -qO- https://raw.githubusercontent.com/bigbluebutton/bbb-install/v3.0.x-release/bbb-install.sh | bash -s -- -w -v noble-300 -s ${var.domain_name != "" ? var.domain_name : aws_eip.bbb.public_ip} -e your-email@example.com"
}

#------------------------------------------------------------------------------
# Monitoring Outputs
#------------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${local.name_prefix}-dashboard"
}

#------------------------------------------------------------------------------
# KMS Outputs
#------------------------------------------------------------------------------
output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = var.enable_kms ? aws_kms_key.main[0].arn : null
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = var.enable_kms ? aws_kms_alias.main[0].name : null
}

#------------------------------------------------------------------------------
# Backup Outputs
#------------------------------------------------------------------------------
output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault"
  value       = var.enable_backups ? aws_backup_vault.main[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the AWS Backup plan"
  value       = var.enable_backups ? aws_backup_plan.main[0].id : null
}

#------------------------------------------------------------------------------
# Health Check Outputs
#------------------------------------------------------------------------------
output "health_check_id" {
  description = "ID of the Route 53 health check"
  value       = var.domain_name != "" && var.enable_health_check ? aws_route53_health_check.bbb[0].id : null
}

#------------------------------------------------------------------------------
# VPC Endpoint Outputs
#------------------------------------------------------------------------------
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "ssm_endpoint_ids" {
  description = "IDs of the SSM VPC endpoints"
  value = var.enable_ssm_endpoints ? {
    ssm          = aws_vpc_endpoint.ssm[0].id
    ssm_messages = aws_vpc_endpoint.ssm_messages[0].id
    ec2_messages = aws_vpc_endpoint.ec2_messages[0].id
  } : null
}
