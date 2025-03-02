provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# https://github.com/cloudposse/terraform-aws-tfstate-backend

module "terraform_state_backend" {
  source  = "cloudposse/tfstate-backend/aws"  
  version = "1.50.0"   
  name       = "tfstate"
  attributes = ["state"]

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  terraform_state_file               = "prod/terraform.tfstate"
  force_destroy                      = false
}