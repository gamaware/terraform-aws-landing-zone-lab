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

module "state" {
  source = "../modules/secure-bucket"

  name                               = var.state_bucket_name
  kms_key_arn                        = aws_kms_key.state.arn
  noncurrent_version_expiration_days = 365
}
