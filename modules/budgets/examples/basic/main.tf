# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "budgets" {
  source = "../.."

  subscriber_emails = ["finops@example.com"]

  budgets = {
    organization-total = { limit_usd = 500 }
  }
}
