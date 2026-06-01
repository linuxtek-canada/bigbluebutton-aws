variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bigbluebutton"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ca-central-1"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "ca-central-1a"
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

variable "domain_name" {
  description = "Domain name for BigBlueButton (required for production)"
  type        = string
}

variable "admin_email" {
  description = "Email address for the initial admin user"
  type        = string
}

variable "admin_domain_name" {
  description = "Custom domain name for admin dashboard (optional)"
  type        = string
  default     = ""
}

variable "admin_acm_certificate_arn" {
  description = "ARN of ACM certificate for admin custom domain"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Provisioning Variables
#------------------------------------------------------------------------------
variable "enable_provisioning" {
  description = "Enable automatic BigBlueButton installation via remote-exec"
  type        = bool
  default     = true
}

variable "bbb_version" {
  description = "BigBlueButton version (e.g., jammy-300 for BBB 3.0)"
  type        = string
  default     = "jammy-300"
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

#------------------------------------------------------------------------------
# Cost Management Variables
#------------------------------------------------------------------------------
variable "monthly_budget_alert" {
  description = "Monthly budget threshold for alerts (USD)"
  type        = number
  default     = 100
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit that triggers auto-stop (USD)"
  type        = number
  default     = 200
}
