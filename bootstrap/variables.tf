variable "aws_region" {
  description = "AWS region for state resources"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bigbluebutton"
}

variable "environments" {
  description = "List of environments to create state resources for"
  type        = list(string)
  default     = ["dev", "prod"]
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "create_oidc_provider" {
  description = "Create a new GitHub OIDC provider (set to false if one already exists in the account)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Purpose   = "terraform-state"
  }
}
