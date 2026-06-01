#------------------------------------------------------------------------------
# AWS WAF WebACL for CloudFront
#------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name        = "${local.name_prefix}-waf"
  description = "WAF rules for ${local.name_prefix} admin dashboard"
  scope       = "CLOUDFRONT"
  provider    = aws.us_east_1

  default_action {
    allow {}
  }

  #----------------------------------------------------------------------------
  # AWS Managed Rules - Common Rule Set
  #----------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  #----------------------------------------------------------------------------
  # AWS Managed Rules - Known Bad Inputs
  #----------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  #----------------------------------------------------------------------------
  # AWS Managed Rules - SQL Injection
  #----------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-sqli"
      sampled_requests_enabled   = true
    }
  }

  #----------------------------------------------------------------------------
  # Rate Limiting Rule
  #----------------------------------------------------------------------------
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  #----------------------------------------------------------------------------
  # IP Allow List (if configured)
  #----------------------------------------------------------------------------
  dynamic "rule" {
    for_each = length(var.allowed_admin_cidrs) > 0 ? [1] : []

    content {
      name     = "IPAllowList"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowed[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-ip-allowlist"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# IP Set for Allowed Admin CIDRs
#------------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "allowed" {
  count = var.enable_waf && length(var.allowed_admin_cidrs) > 0 ? 1 : 0

  name               = "${local.name_prefix}-allowed-ips"
  description        = "Allowed IP addresses for admin access"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allowed_admin_cidrs
  provider           = aws.us_east_1

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# CloudWatch Log Group for WAF
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_waf ? 1 : 0

  name              = "aws-waf-logs-${local.name_prefix}"
  retention_in_days = 30
  provider          = aws.us_east_1

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.main[0].arn
  provider                = aws.us_east_1

  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior = "KEEP"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }

      requirement = "MEETS_ANY"
    }
  }
}
