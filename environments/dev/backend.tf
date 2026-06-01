terraform {
  backend "s3" {
    region         = "ca-central-1"
    bucket         = "bigbluebutton-dev-tfstate-586794440352"
    key            = "dev/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "bigbluebutton-dev-tflock"
  }
}
