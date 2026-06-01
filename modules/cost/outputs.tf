output "budget_alert_sns_topic_arn" {
  description = "ARN of the SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

output "budget_alert_name" {
  description = "Name of the alert-level budget"
  value       = aws_budgets_budget.monthly_alert.name
}

output "budget_limit_name" {
  description = "Name of the limit-level budget"
  value       = aws_budgets_budget.monthly_limit.name
}

output "budget_enforcer_lambda_arn" {
  description = "ARN of the budget enforcer Lambda function"
  value       = var.enable_auto_stop ? aws_lambda_function.budget_enforcer[0].arn : null
}
