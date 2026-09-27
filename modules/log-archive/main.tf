# Central log archive in the log-archive account: one KMS key and one bucket
# that receive the organization CloudTrail and every account's AWS Config
# delivery channel, plus the access-log bucket that audits reads of both.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  trail_arn  = "arn:${local.partition}:cloudtrail:${local.region}:${var.management_account_id}:trail/${var.trail_name}"
}

data "aws_iam_policy_document" "kms" {
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
    sid       = "CloudTrailEncrypt"
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${local.partition}:cloudtrail:*:${var.management_account_id}:trail/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "CloudTrailDescribe"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "ConfigEncrypt"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [var.organization_id]
    }
  }

  dynamic "statement" {
    for_each = length(var.log_reader_role_arns) > 0 ? [1] : []

    content {
      sid       = "OrganizationDecryptForAuditors"
      actions   = ["kms:Decrypt", "kms:DescribeKey"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = var.log_reader_role_arns
      }
    }
  }
}

resource "aws_kms_key" "logs" {
  description             = "Encrypts the organization log archive (CloudTrail and AWS Config)."
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_days
  policy                  = data.aws_iam_policy_document.kms.json
  tags                    = var.tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.bucket_name}"
  target_key_id = aws_kms_key.logs.key_id
}

module "access_logs" {
  source = "../secure-bucket"

  name                               = "${var.bucket_name}-access"
  sse_algorithm                      = "AES256"
  expiration_days                    = var.access_log_expiration_days
  noncurrent_version_expiration_days = 30
  additional_policy_json             = data.aws_iam_policy_document.access_logs_write.json
  force_destroy                      = var.force_destroy
  tags                               = var.tags
}

data "aws_iam_policy_document" "access_logs_write" {
  statement {
    sid       = "S3ServerAccessLogsWrite"
    actions   = ["s3:PutObject"]
    resources = ["arn:${local.partition}:s3:::${var.bucket_name}-access/*"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

data "aws_iam_policy_document" "logs_write" {
  statement {
    sid       = "CloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:${local.partition}:s3:::${var.bucket_name}"]

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

  statement {
    sid     = "CloudTrailWrite"
    actions = ["s3:PutObject"]
    resources = [
      "arn:${local.partition}:s3:::${var.bucket_name}/AWSLogs/${var.management_account_id}/*",
      "arn:${local.partition}:s3:::${var.bucket_name}/AWSLogs/${var.organization_id}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "ConfigAclCheck"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = ["arn:${local.partition}:s3:::${var.bucket_name}"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [var.organization_id]
    }
  }

  statement {
    sid       = "ConfigWrite"
    actions   = ["s3:PutObject"]
    resources = ["arn:${local.partition}:s3:::${var.bucket_name}/AWSLogs/*/Config/*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [var.organization_id]
    }
  }

  dynamic "statement" {
    for_each = var.deny_object_deletion ? [1] : []

    content {
      sid    = "DenyLogTampering"
      effect = "Deny"
      actions = [
        "s3:DeleteBucketPolicy",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:PutBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutLifecycleConfiguration",
      ]
      resources = ["arn:${local.partition}:s3:::${var.bucket_name}", "arn:${local.partition}:s3:::${var.bucket_name}/*"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "ArnNotLike"
        variable = "aws:PrincipalArn"
        values   = ["arn:${local.partition}:iam::${local.account_id}:role/${var.deploy_role_name}"]
      }
    }
  }
}

module "logs" {
  source = "../secure-bucket"

  name                               = var.bucket_name
  kms_key_arn                        = aws_kms_key.logs.arn
  access_log_bucket                  = "${var.bucket_name}-access"
  additional_policy_json             = data.aws_iam_policy_document.logs_write.json
  glacier_transition_days            = var.glacier_transition_days
  expiration_days                    = var.log_expiration_days
  noncurrent_version_expiration_days = 30
  force_destroy                      = var.force_destroy
  tags                               = var.tags

  # The access-log target must exist before logging points at it.
  depends_on = [module.access_logs]
}
