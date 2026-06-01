variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "bigbluebutton"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "ca-central-1a"
}

variable "instance_type" {
  description = "EC2 instance type for BigBlueButton"
  type        = string
  default     = "m6a.2xlarge"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 200

  validation {
    condition     = var.root_volume_size >= 50
    error_message = "Root volume must be at least 50 GB for BigBlueButton."
  }
}

variable "key_name" {
  description = "Name of the SSH key pair for EC2 access"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_web_cidrs" {
  description = "CIDR blocks allowed for web access (HTTP/HTTPS)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Domain name for BigBlueButton (required for HTTPS)"
  type        = string
  default     = ""
}


variable "recordings_bucket_force_destroy" {
  description = "Allow destruction of S3 bucket even with objects (use with caution)"
  type        = bool
  default     = false
}

variable "recordings_lifecycle_days" {
  description = "Number of days to retain recordings before transitioning to Glacier"
  type        = number
  default     = 90
}

#------------------------------------------------------------------------------
# BigBlueButton Installation Variables
#------------------------------------------------------------------------------
variable "enable_provisioning" {
  description = "Enable remote-exec provisioning to install BigBlueButton"
  type        = bool
  default     = true
}

variable "bbb_version" {
  description = "BigBlueButton version (e.g., jammy-300 for BBB 3.0 on Ubuntu 22.04)"
  type        = string
  default     = "jammy-300"
}

variable "admin_email" {
  description = "Email address for Let's Encrypt and admin notifications"
  type        = string
  default     = ""
}

variable "install_greenlight" {
  description = "Install Greenlight room management interface"
  type        = bool
  default     = true
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for provisioning"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "bbb_admin_password" {
  description = "Password for bbb-admin user (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "recording_retention_days" {
  description = "Number of days to retain local recordings before cleanup"
  type        = number
  default     = 30
}

#------------------------------------------------------------------------------
# Monitoring and Alerting Variables
#------------------------------------------------------------------------------
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "cpu_warning_threshold" {
  description = "CPU utilization percentage to trigger warning alarm"
  type        = number
  default     = 80
}

variable "cpu_critical_threshold" {
  description = "CPU utilization percentage to trigger critical alarm"
  type        = number
  default     = 95
}

#------------------------------------------------------------------------------
# Backup Variables
#------------------------------------------------------------------------------
variable "enable_backups" {
  description = "Enable AWS Backup for EBS volumes"
  type        = bool
  default     = true
}

variable "backup_retention_daily" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 7
}

variable "backup_retention_weekly" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 30
}

variable "backup_retention_monthly" {
  description = "Number of days to retain monthly backups"
  type        = number
  default     = 365
}

#------------------------------------------------------------------------------
# KMS Encryption Variables
#------------------------------------------------------------------------------
variable "enable_kms" {
  description = "Enable KMS customer managed keys for encryption"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# VPC Endpoint Variables
#------------------------------------------------------------------------------
variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints for Session Manager without internet"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Health Check Variables
#------------------------------------------------------------------------------
variable "enable_health_check" {
  description = "Enable Route 53 health check for BigBlueButton"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Auto Stop/Start Variables (Cost Savings for Dev)
#------------------------------------------------------------------------------
variable "enable_auto_stop" {
  description = "Enable automatic stop/start for cost savings (recommended for dev)"
  type        = bool
  default     = false
}

variable "auto_stop_schedule" {
  description = "Cron expression for stopping the instance (UTC)"
  type        = string
  default     = "cron(0 22 ? * MON-FRI *)"
}

variable "auto_start_schedule" {
  description = "Cron expression for starting the instance (UTC)"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}
