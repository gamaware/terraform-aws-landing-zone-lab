# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  subscriber_emails = ["finops@example.com"]

  budgets = {
    organization-total = {
      limit_usd = 1500
    }
    workloads = {
      limit_usd  = 1000
      account_id = "555555555555"
    }
    shared-network = {
      limit_usd         = 250
      account_id        = "123456789012"
      actual_thresholds = [50, 90]
      forecast_alert    = false
    }
  }
}

run "budgets_and_alerts" {
  command = plan

  assert {
    condition     = aws_budgets_budget.this["workloads"].limit_amount == "1000.00" && aws_budgets_budget.this["workloads"].time_unit == "MONTHLY"
    error_message = "Limits are monthly USD amounts."
  }

  assert {
    condition     = length(aws_budgets_budget.this["organization-total"].cost_filter) == 0
    error_message = "The organization budget has no account filter."
  }

  assert {
    condition     = toset(one(aws_budgets_budget.this["workloads"].cost_filter).values) == toset(["555555555555"])
    error_message = "Account budgets filter on the linked account."
  }

  assert {
    condition     = length(aws_budgets_budget.this["workloads"].notification) == 3
    error_message = "Default alerts: actual at 80% and 100%, forecast at 100%."
  }

  assert {
    condition     = length([for n in aws_budgets_budget.this["shared-network"].notification : n if n.notification_type == "FORECASTED"]) == 0
    error_message = "forecast_alert = false disables the forecast notification."
  }

  assert {
    condition     = output.total_monthly_limit_usd == 1250
    error_message = "Per-account limits must add up correctly."
  }
}

run "rejects_zero_limit" {
  command = plan

  variables {
    budgets = {
      broken = { limit_usd = 0 }
    }
  }

  expect_failures = [var.budgets]
}

run "rejects_missing_subscribers" {
  command = plan

  variables {
    subscriber_emails = []
  }

  expect_failures = [var.subscriber_emails]
}
