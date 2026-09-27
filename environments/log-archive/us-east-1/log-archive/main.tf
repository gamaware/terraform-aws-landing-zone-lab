locals {
  stack = "log-archive"
}

module "log_archive" {
  source = "../../../../modules/log-archive"

  bucket_name           = var.bucket_name
  organization_id       = var.organization_id
  management_account_id = var.management_account_id
  trail_name            = "organization-trail"
  deploy_role_name      = var.deploy_role_name
  log_reader_role_arns  = ["arn:aws:iam::${var.security_account_id}:role/aws-reserved/sso.amazonaws.com/*AWSReservedSSO_SecurityAudit_*"]
}
