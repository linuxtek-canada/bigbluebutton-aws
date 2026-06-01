#------------------------------------------------------------------------------
# BigBlueButton Module - Dev Environment
#------------------------------------------------------------------------------
module "bigbluebutton" {
  source = "../../modules/bigbluebutton"

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "dev"

  # AWS Configuration
  aws_region        = var.aws_region
  availability_zone = var.availability_zone

  # Network Configuration
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"

  # EC2 Configuration
  instance_type    = "m6a.2xlarge"
  root_volume_size = 120
  key_name         = var.key_name

  # Security Configuration
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  allowed_web_cidrs = ["0.0.0.0/0"]

  # BigBlueButton Configuration
  domain_name = var.domain_name

  # S3 Configuration
  recordings_bucket_force_destroy = true # Allow destruction in dev
  recordings_lifecycle_days       = 30   # Shorter retention in dev

  # Provisioning Configuration
  enable_provisioning      = var.enable_provisioning
  bbb_version              = var.bbb_version
  admin_email              = var.admin_email
  install_greenlight       = var.install_greenlight
  ssh_private_key_path     = var.ssh_private_key_path
  bbb_admin_password       = var.bbb_admin_password
  recording_retention_days = 30

  # Monitoring Configuration
  alert_email = var.admin_email

  # Backup Configuration (disabled for dev to save costs)
  enable_backups = false

  # KMS Encryption (disabled for dev to save costs)
  enable_kms = false

  # VPC Endpoints (disabled for dev)
  enable_ssm_endpoints = false

  # Health Check (disabled for dev)
  enable_health_check = false

  # Auto Stop/Start (enabled for dev to save costs)
  enable_auto_stop    = true
  auto_stop_schedule  = var.auto_stop_schedule
  auto_start_schedule = var.auto_start_schedule
}

#------------------------------------------------------------------------------
# Admin Dashboard Module - Dev Environment
#------------------------------------------------------------------------------
module "admin_dashboard" {
  source = "../../modules/admin-dashboard"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "dev"
  aws_region   = var.aws_region

  # BigBlueButton Instance
  bbb_instance_id = module.bigbluebutton.instance_id

  # Recordings Bucket
  recordings_bucket_arn  = module.bigbluebutton.recordings_bucket_arn
  recordings_bucket_name = module.bigbluebutton.recordings_bucket_name

  # Admin Configuration
  admin_email = var.admin_email

  # Optional: Custom domain for admin dashboard
  domain_name         = var.admin_domain_name
  acm_certificate_arn = var.admin_acm_certificate_arn

  # WAF Configuration (enabled by default)
  enable_waf     = var.enable_waf
  waf_rate_limit = 1000
}

#------------------------------------------------------------------------------
# Security Module - Dev Environment
#------------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "dev"
  aws_region   = var.aws_region

  # CloudTrail Configuration (minimal for dev)
  enable_cloudtrail         = var.enable_cloudtrail
  cloudtrail_retention_days = 30
  enable_s3_data_events     = false

  # S3 bucket to monitor (recordings)
  s3_bucket_arns = [module.bigbluebutton.recordings_bucket_arn]

  # GuardDuty Configuration
  enable_guardduty = var.enable_guardduty

  # AWS Config Configuration (disabled for dev)
  enable_config = false

  # SNS Topic for alerts
  sns_topic_arn            = module.bigbluebutton.sns_topic_arn
  enable_sns_notifications = true
}

#------------------------------------------------------------------------------
# Cost Module - Dev Environment
#------------------------------------------------------------------------------
module "cost" {
  source = "../../modules/cost"

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "dev"
  aws_region   = var.aws_region

  # Budget Configuration
  monthly_budget_alert_threshold = var.monthly_budget_alert
  monthly_budget_limit           = var.monthly_budget_limit
  alert_email                    = var.admin_email

  # EC2 Instance to stop when budget exceeded
  ec2_instance_id = module.bigbluebutton.instance_id
}
