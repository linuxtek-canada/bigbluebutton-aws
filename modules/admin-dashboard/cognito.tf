#------------------------------------------------------------------------------
# Cognito User Pool
#------------------------------------------------------------------------------
resource "aws_cognito_user_pool" "admin" {
  name = "${local.name_prefix}-admin-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_subject = "BigBlueButton Admin - Your temporary password"
      email_message = "Your username is {username} and temporary password is {####}"
      sms_message   = "Your username is {username} and temporary password is {####}"
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Cognito User Pool Client
#------------------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "admin" {
  name         = "${local.name_prefix}-admin-client"
  user_pool_id = aws_cognito_user_pool.admin.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]

  callback_urls = [
    "https://${aws_cloudfront_distribution.admin.domain_name}/callback"
  ]

  logout_urls = [
    "https://${aws_cloudfront_distribution.admin.domain_name}/logout"
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
}

#------------------------------------------------------------------------------
# Cognito User Pool Domain
#------------------------------------------------------------------------------
resource "aws_cognito_user_pool_domain" "admin" {
  domain       = "${local.name_prefix}-admin-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.admin.id
}

#------------------------------------------------------------------------------
# Initial Admin User
#------------------------------------------------------------------------------
resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.admin.id
  username     = var.admin_email

  attributes = {
    email          = var.admin_email
    email_verified = true
  }

  lifecycle {
    ignore_changes = [
      attributes,
      enabled,
      password
    ]
  }
}
