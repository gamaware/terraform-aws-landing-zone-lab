# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "444455556666"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"
      key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }
}

variables {
  bucket_name           = "harbor-goods-log-archive-444455556666"
  organization_id       = "o-exampleorgid"
  management_account_id = "111122223333"
}

run "archive_is_encrypted_and_scoped" {
  command = plan

  assert {
    condition     = aws_kms_key.logs.enable_key_rotation
    error_message = "The log key must rotate."
  }

  assert {
    condition     = module.logs.encryption == "aws:kms" && module.access_logs.encryption == "AES256"
    error_message = "Logs use SSE-KMS; the access-log target uses SSE-S3."
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.logs_write.statement :
      s.sid == "CloudTrailWrite" && contains(s.resources, "arn:aws:s3:::harbor-goods-log-archive-444455556666/AWSLogs/o-exampleorgid/*")
    ])
    error_message = "The organization trail must be able to write under AWSLogs/<org-id>/."
  }

  assert {
    condition = alltrue([
      for sid in ["CloudTrailAclCheck", "CloudTrailWrite"] : anytrue(flatten([
        for s in data.aws_iam_policy_document.logs_write.statement : [
          for c in s.condition : c.variable == "aws:SourceArn" && toset(c.values) == toset(["arn:aws:cloudtrail:us-east-1:111122223333:trail/organization-trail"])
        ] if s.sid == sid
      ]))
    ])
    error_message = "Both CloudTrail statements must be pinned to the management account's organization trail."
  }

  assert {
    condition = alltrue([
      for sid in ["ConfigAclCheck", "ConfigWrite"] : anytrue(flatten([
        for s in data.aws_iam_policy_document.logs_write.statement : [
          for c in s.condition : c.variable == "aws:SourceOrgID" && toset(c.values) == toset(["o-exampleorgid"])
        ] if s.sid == sid
      ]))
    ])
    error_message = "Both AWS Config statements must be limited to the organization."
  }

  assert {
    condition     = anytrue([for s in data.aws_iam_policy_document.logs_write.statement : s.sid == "DenyLogTampering" && s.effect == "Deny" && contains(s.actions, "s3:PutBucketPolicy")])
    error_message = "Log deletion must be denied by default."
  }

  assert {
    condition     = length([for s in data.aws_iam_policy_document.kms.statement : s if s.sid == "OrganizationDecryptForAuditors"]) == 0
    error_message = "No cross-account decrypt statement when no reader roles are given."
  }
}

run "auditor_decrypt_is_org_scoped" {
  command = plan

  variables {
    log_reader_role_arns = ["arn:aws:iam::777788889999:role/aws-reserved/sso.amazonaws.com/*AWSReservedSSO_SecurityAudit_*"]
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.kms.statement :
      s.sid == "OrganizationDecryptForAuditors" && anytrue([for c in s.condition : c.variable == "aws:PrincipalOrgID" && toset(c.values) == toset(["o-exampleorgid"])])
    ])
    error_message = "Auditor decrypt must require the organization ID."
  }
}

run "live_test_mode_relaxes_deletion_guard" {
  command = plan

  variables {
    deny_object_deletion = false
    force_destroy        = true
  }

  assert {
    condition     = length([for s in data.aws_iam_policy_document.logs_write.statement : s if s.sid == "DenyLogTampering"]) == 0
    error_message = "The live test must be able to empty and delete the bucket."
  }
}

run "rejects_organization_wide_reader" {
  command = plan

  variables {
    log_reader_role_arns = ["arn:aws:iam::*:role/*"]
  }

  expect_failures = [var.log_reader_role_arns]
}

run "rejects_short_retention" {
  command = plan

  variables {
    log_expiration_days = 90
  }

  expect_failures = [var.log_expiration_days]
}

run "rejects_bad_organization_id" {
  command = plan

  variables {
    organization_id = "r-examplerootid111"
  }

  expect_failures = [var.organization_id]
}
