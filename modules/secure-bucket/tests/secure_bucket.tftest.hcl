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

variables {
  name        = "harbor-goods-example"
  kms_key_arn = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"
}

run "kms_bucket_is_hardened" {
  command = plan

  variables {
    expiration_days = 400
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.kms.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "SSE-KMS must be the default encryption."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.kms.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_arn
    error_message = "Objects must be encrypted with the given customer managed key."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.kms.rule).bucket_key_enabled
    error_message = "Bucket keys cut KMS request cost and must be on."
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

}

run "no_expiration_by_default" {
  command = plan

  assert {
    condition     = length(one(aws_s3_bucket_lifecycle_configuration.this.rule).expiration) == 0
    error_message = "No expiration rule when expiration_days is null."
  }
}

run "rejects_a_value_that_is_not_a_kms_key" {
  command = plan

  variables {
    kms_key_arn = "AES256"
  }

  expect_failures = [var.kms_key_arn]
}

run "rejects_invalid_bucket_name" {
  command = plan

  variables {
    name = "Harbor_Goods"
  }

  expect_failures = [var.name]
}
