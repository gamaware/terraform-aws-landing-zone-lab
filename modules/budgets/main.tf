# Monthly cost budgets, created in the management account where consolidated
# billing data lives. A budget with account_id tracks one linked account; one
# without it tracks the whole organization.

resource "aws_budgets_budget" "this" {
  for_each = var.budgets

  name         = each.key
  budget_type  = "COST"
  limit_amount = format("%.2f", each.value.limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  tags         = var.tags

  dynamic "cost_filter" {
    for_each = each.value.account_id == null ? [] : [each.value.account_id]
    content {
      name   = "LinkedAccount"
      values = [cost_filter.value]
    }
  }

  dynamic "notification" {
    for_each = each.value.actual_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = var.subscriber_emails
    }
  }

  dynamic "notification" {
    for_each = each.value.forecast_alert ? [each.value.forecast_threshold] : []
    content {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "FORECASTED"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = var.subscriber_emails
    }
  }
}
