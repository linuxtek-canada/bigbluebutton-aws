provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "terraform_state_backend" {
  # https://registry.terraform.io/modules/cloudposse/tfstate-backend/aws/latest
  # https://github.com/cloudposse/terraform-aws-tfstate-backend
  source  = "cloudposse/tfstate-backend/aws"
  version = "1.5.0"

  name        = "tfstate"
  namespace   = var.namespace
  environment = var.environment
  attributes  = [data.aws_caller_identity.current.account_id]

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  terraform_state_file               = "prod/terraform.tfstate"
  force_destroy                      = false
}

module "bigbluebutton" {
  source                = "../../modules/bigbluebutton"
  namespace             = var.namespace
  environment           = var.environment
  aws_region            = var.aws_region
  aws_availability_zone = var.aws_availability_zone
  ssh_location          = var.ssh_location
  ssh_public_key        = var.ssh_public_key

}