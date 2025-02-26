# --- variables.tf ---

variable "aws_region" {
  default     = "ca-central-1"
  description = "AWS Region to Deploy Resources to"
  type        = string
}

variable "aws_availability_zone" {
  default     = "cac1-az1"
  description = "AWS AZ to Deploy to"
  type        = string
}

variable "environment" {
  description = "Environment Name"
  type        = string
}

variable "namespace" {
  description = "Abbreviation of organization"
  type        = string
}

variable "vpc-cidr" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR Block"
  type        = string
}

variable "public_subnet_1" {
  default     = "10.0.1.0/24"
  description = "public_subnet_1"
  type        = string
}
variable "private_subnet_1" {
  default     = "10.0.2.0/24"
  description = "private_subnet_1"
  type        = string
}

variable "ssh_location" {
  default     = ["0.0.0.0/0"]
  description = "Use to restrict IP for SSH access"
  type        = list(any)
}

variable "ssh_public_key" {
  default     = ""
  description = "Public SSH Key to add to EC2 Instance"
  type        = string
}

variable "ami_id" {
  # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  default     = "ami-0a474b3a85d51a5e5"
  description = "AMI ID of image to deploy"
  type        = string
}

variable "ec2_instance_type" {
  default     = "c5.2xlarge"
  description = "EC2 Instance Type"
  type        = string
}