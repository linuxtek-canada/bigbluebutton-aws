terraform {
  backend "s3" {
    region         = "ca-central-1"
    bucket         = "bigbluebutton-prod-tfstate-586794440352"
    key            = "prod/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "bigbluebutton-prod-tflock"
  }
}
