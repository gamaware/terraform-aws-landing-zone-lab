# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region              = var.region
  allowed_account_ids = ["111122223333"]
}

module "budgets" {
  source = "../.."

  subscriber_emails = ["finops@example.com"]

  budgets = {
    organization-total = { limit_usd = 500 }
  }
}
