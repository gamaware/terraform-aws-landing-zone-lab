# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "log_archive" {
  source = "../.."

  bucket_name           = "harbor-goods-log-archive-444455556666"
  organization_id       = "o-exampleorgid"
  management_account_id = "111122223333"
}
