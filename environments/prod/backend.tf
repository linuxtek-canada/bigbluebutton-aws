terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region  = "ca-central-1"
    bucket  = "kwlug-prod-tfstate-586794440352"
    key     = "prod/terraform.tfstate"
    profile = ""
    encrypt = "true"

    dynamodb_table = "kwlug-prod-tfstate-586794440352-lock"
  }
}
