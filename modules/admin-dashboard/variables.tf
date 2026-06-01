variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "bbb_instance_id" {
  description = "ID of the BigBlueButton EC2 instance to control"
  type        = string
}

variable "recordings_bucket_arn" {
  description = "ARN of the S3 bucket containing recordings"
  type        = string
}

variable "recordings_bucket_name" {
  description = "Name of the S3 bucket containing recordings"
  type        = string
}

variable "admin_email" {
  description = "Email address for the initial admin user"
  type        = string
}

variable "allowed_admin_cidrs" {
  description = "CIDR blocks allowed to access the admin dashboard"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain (required if domain_name is set)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# WAF Variables
#------------------------------------------------------------------------------
variable "enable_waf" {
  description = "Enable AWS WAF for CloudFront distribution"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5 minutes per IP before rate limiting"
  type        = number
  default     = 1000
}
