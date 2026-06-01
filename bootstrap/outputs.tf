output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.oidc_provider_arn
}

output "state_buckets" {
  description = "S3 bucket names for Terraform state"
  value = {
    for env in var.environments : env => aws_s3_bucket.terraform_state[env].id
  }
}

output "lock_tables" {
  description = "DynamoDB table names for state locking"
  value = {
    for env in var.environments : env => aws_dynamodb_table.terraform_lock[env].name
  }
}

output "github_actions_role_arns" {
  description = "IAM role ARNs for GitHub Actions"
  value = {
    for env in var.environments : env => aws_iam_role.github_actions[env].arn
  }
}

output "backend_config" {
  description = "Backend configuration for each environment"
  value = {
    for env in var.environments : env => {
      bucket         = aws_s3_bucket.terraform_state[env].id
      key            = "terraform.tfstate"
      region         = var.aws_region
      encrypt        = true
      dynamodb_table = aws_dynamodb_table.terraform_lock[env].name
    }
  }
}

output "github_actions_config" {
  description = "Configuration for GitHub Actions secrets"
  value = {
    AWS_REGION = var.aws_region
    role_arns = {
      for env in var.environments : env => aws_iam_role.github_actions[env].arn
    }
  }
}
