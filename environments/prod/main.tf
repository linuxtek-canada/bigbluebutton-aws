#------------------------------------------------------------------------------
# BigBlueButton Module - Production Environment
#------------------------------------------------------------------------------
module "bigbluebutton" {
  source = "../../modules/bigbluebutton"

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "prod"

  # AWS Configuration
  aws_region        = var.aws_region
  availability_zone = var.availability_zone

  # Network Configuration
  vpc_cidr           = "10.1.0.0/16"
  public_subnet_cidr = "10.1.1.0/24"

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
  recordings_bucket_force_destroy = false # Protect production data
  recordings_lifecycle_days       = 90    # Standard retention

  # Provisioning Configuration
  enable_provisioning      = var.enable_provisioning
  bbb_version              = var.bbb_version
  admin_email              = var.admin_email
  install_greenlight       = var.install_greenlight
  ssh_private_key_path     = var.ssh_private_key_path
  bbb_admin_password       = var.bbb_admin_password
  recording_retention_days = 90

  # Monitoring Configuration
  alert_email            = var.admin_email
  cpu_warning_threshold  = 80
  cpu_critical_threshold = 95

  # Backup Configuration (enabled for production)
  enable_backups           = true
  backup_retention_daily   = 7
  backup_retention_weekly  = 30
  backup_retention_monthly = 365

  # KMS Encryption (enabled for production)
  enable_kms = true

  # VPC Endpoints (enabled for production)
  enable_ssm_endpoints = false

  # Health Check (enabled for production)
  enable_health_check = true

  # Auto Stop/Start (disabled for production)
  enable_auto_stop = false
}

#------------------------------------------------------------------------------
# Admin Dashboard Module - Production Environment
#------------------------------------------------------------------------------
module "admin_dashboard" {
  source = "../../modules/admin-dashboard"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "prod"
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

  # WAF Configuration (enabled with stricter limits for production)
  enable_waf     = true
  waf_rate_limit = 500
}

#------------------------------------------------------------------------------
# Security Module - Production Environment
#------------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "prod"
  aws_region   = var.aws_region

  # CloudTrail Configuration (full logging for production)
  enable_cloudtrail         = true
  cloudtrail_retention_days = 365
  enable_s3_data_events     = true

  # S3 bucket to monitor (recordings)
  s3_bucket_arns = [module.bigbluebutton.recordings_bucket_arn]

  # GuardDuty Configuration
  enable_guardduty = true

  # AWS Config Configuration
  enable_config = false

  # SNS Topic for alerts
  sns_topic_arn            = module.bigbluebutton.sns_topic_arn
  enable_sns_notifications = true
}

#------------------------------------------------------------------------------
# Cost Module - Production Environment
#------------------------------------------------------------------------------
module "cost" {
  source = "../../modules/cost"

  # Project Configuration
  project_name = "bigbluebutton"
  environment  = "prod"
  aws_region   = var.aws_region

  # Budget Configuration (higher limits for production)
  monthly_budget_alert_threshold = var.monthly_budget_alert
  monthly_budget_limit           = var.monthly_budget_limit
  alert_email                    = var.admin_email

  # EC2 Instance to stop when budget exceeded
  ec2_instance_id = module.bigbluebutton.instance_id
}
