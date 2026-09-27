# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::harbor-goods-example"
    }
  }
}

run "kms_bucket_with_access_logging" {
  command = plan

  variables {
    name              = "harbor-goods-example"
    kms_key_arn       = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    access_log_bucket = "harbor-goods-example-access"
    expiration_days   = 400
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.kms) == 1 && length(aws_s3_bucket_server_side_encryption_configuration.s3_managed) == 0
    error_message = "A KMS key must select SSE-KMS only."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.kms[0].rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "SSE-KMS must be the default encryption."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.kms[0].rule).bucket_key_enabled
    error_message = "Bucket keys cut KMS request cost and must be on."
  }

  assert {
    condition     = aws_s3_bucket_logging.this[0].target_bucket == "harbor-goods-example-access"
    error_message = "Access logs must go to the given bucket."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All four public access block settings must be on."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this.rule).expiration).days == 400
    error_message = "Expiration must follow expiration_days."
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy must default to false."
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.this.statement :
      s.sid == "DenyInsecureTransport" && s.effect == "Deny" && one(s.condition).variable == "aws:SecureTransport"
    ])
    error_message = "The bucket policy must deny requests without TLS."
  }

  assert {
    condition     = output.encryption == "aws:kms"
    error_message = "The encryption output must report SSE-KMS."
  }
}

run "access_log_target_uses_sse_s3" {
  command = plan

  variables {
    name          = "harbor-goods-example-access"
    sse_algorithm = "AES256"
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.s3_managed) == 1 && length(aws_s3_bucket_server_side_encryption_configuration.kms) == 0
    error_message = "Without a KMS key the bucket must use SSE-S3, the only option for access-log targets."
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 0
    error_message = "The access-log target must not log to itself."
  }

  assert {
    condition     = length(one(aws_s3_bucket_lifecycle_configuration.this.rule).expiration) == 0
    error_message = "No expiration rule when expiration_days is null."
  }
}

run "rejects_kms_without_key" {
  command = plan

  variables {
    name = "harbor-goods-example"
  }

  expect_failures = [var.kms_key_arn]
}

run "rejects_invalid_bucket_name" {
  command = plan

  variables {
    name          = "Harbor_Goods"
    sse_algorithm = "AES256"
  }

  expect_failures = [var.name]
}
