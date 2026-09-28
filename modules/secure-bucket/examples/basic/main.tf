# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "bucket" {
  source = "../.."

  name        = "harbor-goods-example"
  kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
}
