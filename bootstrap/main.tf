# Remote state for every stack in this repository: one versioned, encrypted
# bucket in the management account. S3 native locking (use_lockfile) replaces
# the DynamoDB lock table, so there is no second resource to protect.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "state_kms" {
  #checkov:skip=CKV_AWS_109:Key policy: Resource "*" means this key only, and kms:* for the account root is the AWS default admin statement.
  #checkov:skip=CKV_AWS_111:Key policy: service writes are constrained by encryption-context, source ARN or organization conditions.
  #checkov:skip=CKV_AWS_356:Key policy: "*" is the only valid Resource value in a KMS key policy.
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform state for the landing zone."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.state_kms.json
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.state_bucket_name}"
  target_key_id = aws_kms_key.state.key_id
}

data "aws_iam_policy_document" "access_logs_write" {
  statement {
    sid       = "S3ServerAccessLogsWrite"
    actions   = ["s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket_name}-access/*"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "access_logs" {
  source = "../modules/secure-bucket"

  name                               = "${var.state_bucket_name}-access"
  sse_algorithm                      = "AES256"
  additional_policy_json             = data.aws_iam_policy_document.access_logs_write.json
  expiration_days                    = 180
  noncurrent_version_expiration_days = 30
}

module "state" {
  source = "../modules/secure-bucket"

  name                               = var.state_bucket_name
  kms_key_arn                        = aws_kms_key.state.arn
  access_log_bucket                  = "${var.state_bucket_name}-access"
  noncurrent_version_expiration_days = 365

  # The access-log target must exist before logging points at it.
  depends_on = [module.access_logs]
}
