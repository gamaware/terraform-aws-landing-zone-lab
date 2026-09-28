# AWS Config recorder for one account and region, delivering to the central
# log-archive bucket. Every member account runs this in its baseline stack;
# the security account's organization aggregator reads the results.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  config_service_role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
}

resource "aws_iam_service_linked_role" "config" {
  count = var.create_service_linked_role ? 1 : 0

  aws_service_name = "config.amazonaws.com"
}

resource "aws_config_configuration_recorder" "this" {
  #checkov:skip=CKV2_AWS_48:All supported types are recorded; global types only in the home region to avoid duplicate IAM records (record_global_resources).
  name     = "default"
  role_arn = var.create_service_linked_role ? aws_iam_service_linked_role.config[0].arn : local.config_service_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = var.record_global_resources
  }

  recording_mode {
    recording_frequency = var.recording_frequency
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "default"
  s3_bucket_name = var.delivery_bucket_name
  s3_kms_key_arn = var.delivery_kms_key_arn

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
