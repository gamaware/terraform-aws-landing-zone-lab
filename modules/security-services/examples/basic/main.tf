# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region              = var.region
  allowed_account_ids = ["777788889999"]
}

module "security_services" {
  source = "../.."
}
