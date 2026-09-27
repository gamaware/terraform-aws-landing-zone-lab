provider "aws" {
  region = var.region

  # Management-account credentials assume the role Organizations created
  # in the member account. allowed_account_ids stops a wrong role ARN
  # from ever applying to the wrong account.
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/${var.deploy_role_name}"
    session_name = "terraform-landing-zone"
  }

  allowed_account_ids = [var.account_id]

  default_tags {
    tags = merge(var.tags, { Stack = local.stack })
  }
}
