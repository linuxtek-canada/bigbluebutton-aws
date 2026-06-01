#------------------------------------------------------------------------------
# AWS Backup Vault
#------------------------------------------------------------------------------
resource "aws_backup_vault" "main" {
  count = var.enable_backups ? 1 : 0

  name = "${local.name_prefix}-backup-vault"

  tags = {
    Name = "${local.name_prefix}-backup-vault"
  }
}

#------------------------------------------------------------------------------
# AWS Backup Plan
#------------------------------------------------------------------------------
resource "aws_backup_plan" "main" {
  count = var.enable_backups ? 1 : 0

  name = "${local.name_prefix}-backup-plan"

  # Daily backup
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * * *)" # 5 AM UTC daily

    lifecycle {
      delete_after = 7 # Keep for 7 days
    }

    recovery_point_tags = {
      Type = "daily"
    }
  }

  # Weekly backup
  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * SUN *)" # 5 AM UTC every Sunday

    lifecycle {
      delete_after = 30 # Keep for 30 days
    }

    recovery_point_tags = {
      Type = "weekly"
    }
  }

  # Monthly backup (for prod only based on environment check in selection)
  rule {
    rule_name         = "monthly-backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 1 * ? *)" # 5 AM UTC on 1st of each month

    lifecycle {
      cold_storage_after = 30  # Move to cold storage after 30 days
      delete_after       = 365 # Keep for 1 year
    }

    recovery_point_tags = {
      Type = "monthly"
    }
  }

  tags = {
    Name = "${local.name_prefix}-backup-plan"
  }
}

#------------------------------------------------------------------------------
# IAM Role for AWS Backup
#------------------------------------------------------------------------------
resource "aws_iam_role" "backup" {
  count = var.enable_backups ? 1 : 0

  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  count = var.enable_backups ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  count = var.enable_backups ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

#------------------------------------------------------------------------------
# Backup Selection - EC2 Instance
#------------------------------------------------------------------------------
resource "aws_backup_selection" "ec2" {
  count = var.enable_backups ? 1 : 0

  name         = "${local.name_prefix}-ec2-selection"
  plan_id      = aws_backup_plan.main[0].id
  iam_role_arn = aws_iam_role.backup[0].arn

  resources = [
    aws_instance.bbb.arn
  ]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Name"
    value = "${local.name_prefix}-server"
  }
}
