locals {
  stack = "baseline"
}

# Every member account records its configuration to the central archive.
# Global resources (IAM) are recorded only in the home region.
module "config_recorder" {
  source = "../../../../modules/config-recorder"

  delivery_bucket_name    = var.log_bucket_name
  delivery_kms_key_arn    = var.log_kms_key_arn
  record_global_resources = var.region == "us-east-1"
  recording_frequency     = var.recording_frequency
}
