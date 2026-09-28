provider "aws" {
  region = var.region

  allowed_account_ids = [var.account_id]

  default_tags {
    tags = merge(var.tags, { Stack = local.stack })
  }
}
