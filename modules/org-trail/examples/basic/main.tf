# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "org_trail" {
  source = "../.."

  log_bucket_name = "harbor-goods-log-archive-444455556666"
  log_kms_key_arn = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"

  data_event_bucket_arns = ["arn:aws:s3:::harbor-goods-tfstate-111122223333"]
}
