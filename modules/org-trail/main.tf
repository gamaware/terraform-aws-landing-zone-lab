# Organization CloudTrail, created in the management account and delivered to
# the log-archive bucket. A copy streams to CloudWatch Logs in the management
# account so metric filters and alarms can act on it.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  trail_arn  = "arn:${local.partition}:cloudtrail:${local.region}:${local.account_id}:trail/${var.trail_name}"
}

data "aws_iam_policy_document" "log_group_kms" {
  #checkov:skip=CKV_AWS_109:Key policy: Resource "*" means this key only, and kms:* for the account root is the AWS default admin statement.
  #checkov:skip=CKV_AWS_111:Key policy: service writes are constrained by encryption-context, source ARN or organization conditions.
  #checkov:skip=CKV_AWS_356:Key policy: "*" is the only valid Resource value in a KMS key policy.
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid = "CloudWatchLogsEncrypt"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${var.log_group_name}"]
    }
  }

  # CloudTrail publishes delivery notifications to an encrypted SNS topic, so
  # it needs this key too. An AWS managed key cannot grant that.
  statement {
    sid       = "CloudTrailPublishEncrypted"
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_kms_key" "log_group" {
  description             = "Encrypts the CloudWatch Logs copy and the delivery notifications of the organization trail."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.log_group_kms.json
  tags                    = var.tags
}

resource "aws_cloudwatch_log_group" "trail" {
  name              = var.log_group_name
  retention_in_days = var.log_group_retention_days
  kms_key_id        = aws_kms_key.log_group.arn
  tags              = var.tags
}

data "aws_iam_policy_document" "trail_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_iam_role" "trail_to_logs" {
  name               = "${var.trail_name}-cloudwatch-logs"
  assume_role_policy = data.aws_iam_policy_document.trail_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "trail_to_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:log-stream:*"]
  }
}

resource "aws_iam_role_policy" "trail_to_logs" {
  name   = "write-trail-log-group"
  role   = aws_iam_role.trail_to_logs.id
  policy = data.aws_iam_policy_document.trail_to_logs.json
}

resource "aws_sns_topic" "trail" {
  name              = "${var.trail_name}-delivery"
  kms_master_key_id = aws_kms_key.log_group.arn
  tags              = var.tags
}

data "aws_iam_policy_document" "sns" {
  statement {
    sid       = "CloudTrailPublish"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.trail.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_sns_topic_policy" "trail" {
  arn    = aws_sns_topic.trail.arn
  policy = data.aws_iam_policy_document.sns.json
}

resource "aws_cloudtrail" "organization" {
  name                          = var.trail_name
  s3_bucket_name                = var.log_bucket_name
  kms_key_id                    = var.log_kms_key_arn
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail_to_logs.arn
  sns_topic_name                = aws_sns_topic.trail.name
  tags                          = var.tags

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_iam_role_policy.trail_to_logs, aws_sns_topic_policy.trail]
}
