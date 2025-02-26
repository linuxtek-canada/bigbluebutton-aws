variable "namespace" {
  description = "Abbreviation of organization"
  type        = string
}

variable "environment" {
  description = "Environment Name"
  type        = string
}

variable "aws_region" {
  default     = "ca-central-1"
  description = "AWS Region to Deploy Resources to"
  type        = string
}

variable "aws_availability_zone" {
  default     = "ca-central-1a"
  description = "AWS AZ to Deploy to"
  type        = string
}

variable "ami_id" {
  # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  default     = "ami-0a474b3a85d51a5e5"
  description = "AMI ID of image to deploy"
  type        = string
}

variable "ec2_instance_type" {
  default     = "c5a.2xlarge"
  description = "EC2 Instance Type"
  type        = string
}

variable "ssh_location" {
  description = "SSH IP address or range to allow"
  default     = ["0.0.0.0/0"]
  type        = list(any)
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH Public Key to add to EC2 Instance"
  type        = string
  sensitive   = true
}