locals {
  stack = "budgets"
}

module "budgets" {
  source = "../../../../modules/budgets"

  subscriber_emails = var.subscriber_emails

  budgets = {
    organization-total = {
      limit_usd = 1500
    }
    workloads = {
      limit_usd  = 1000
      account_id = var.member_account_ids["workloads"]
    }
    shared-network = {
      limit_usd  = 250
      account_id = var.member_account_ids["shared"]
    }
    security-tooling = {
      limit_usd  = 150
      account_id = var.member_account_ids["security"]
    }
    log-archive = {
      limit_usd  = 50
      account_id = var.member_account_ids["log-archive"]
    }
  }
}
