locals {
  stack = "org-trail"
}

module "org_trail" {
  source = "../../../../modules/org-trail"

  trail_name      = "organization-trail"
  log_bucket_name = var.log_bucket_name
  log_kms_key_arn = var.log_kms_key_arn

  # Terraform state reads and writes are audited as S3 data events.
  data_event_bucket_arns = ["arn:aws:s3:::${var.state_bucket_name}"]
}
