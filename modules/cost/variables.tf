variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alert_email" {
  description = "Email address for budget alerts"
  type        = string
}

variable "monthly_budget_alert_threshold" {
  description = "Monthly budget alert threshold in USD"
  type        = number
  default     = 100
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD (triggers resource shutdown)"
  type        = number
  default     = 200
}

variable "ec2_instance_id" {
  description = "EC2 instance ID to stop when budget limit is reached"
  type        = string
}

variable "enable_auto_stop" {
  description = "Enable automatic EC2 shutdown when budget limit is reached"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
