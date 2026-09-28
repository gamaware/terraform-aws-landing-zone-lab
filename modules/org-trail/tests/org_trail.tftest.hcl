# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
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
}

variables {
  log_bucket_name = "harbor-goods-log-archive-444455556666"
  log_kms_key_arn = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"
}

run "organization_trail_settings" {
  command = plan

  assert {
    condition     = aws_cloudtrail.organization.is_organization_trail && aws_cloudtrail.organization.is_multi_region_trail
    error_message = "The trail must cover every account and region."
  }

  assert {
    condition     = aws_cloudtrail.organization.enable_log_file_validation
    error_message = "Log file validation must be on so tampering is detectable."
  }

  assert {
    condition     = aws_cloudtrail.organization.kms_key_id == "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    error_message = "Trail files must be encrypted with the log-archive key."
  }

  assert {
    condition     = aws_cloudtrail.organization.s3_bucket_name == "harbor-goods-log-archive-444455556666"
    error_message = "The trail must deliver to the central bucket."
  }

  assert {
    condition     = aws_cloudwatch_log_group.trail.retention_in_days >= 365
    error_message = "The CloudWatch copy must keep at least a year."
  }

  assert {
    condition     = anytrue([for s in data.aws_iam_policy_document.log_group_kms.statement : s.sid == "CloudTrailPublishEncrypted"])
    error_message = "CloudTrail needs the key to publish to the encrypted SNS topic; an AWS managed key cannot grant it."
  }

  assert {
    condition     = aws_kms_key.log_group.enable_key_rotation
    error_message = "The log group key must rotate."
  }

  assert {
    condition = anytrue([
      for c in one(data.aws_iam_policy_document.trail_assume.statement).condition :
      c.variable == "aws:SourceArn" && toset(c.values) == toset(["arn:aws:cloudtrail:us-east-1:111122223333:trail/organization-trail"])
    ])
    error_message = "Only this trail may assume the CloudWatch Logs delivery role."
  }
}

run "rejects_key_alias" {
  command = plan

  variables {
    log_kms_key_arn = "alias/log-archive"
  }

  expect_failures = [var.log_kms_key_arn]
}

run "rejects_short_log_group_retention" {
  command = plan

  variables {
    log_group_retention_days = 30
  }

  expect_failures = [var.log_group_retention_days]
}

run "data_events_replace_server_access_logs" {
  command = plan

  variables {
    data_event_bucket_arns = ["arn:aws:s3:::harbor-goods-tfstate-111122223333"]
  }

  assert {
    condition = anytrue([
      for s in aws_cloudtrail.organization.advanced_event_selector : s.name == "Log archive reads" && anytrue([
        for f in s.field_selector : f.field == "resources.ARN" && toset(f.starts_with) == toset(["arn:aws:s3:::harbor-goods-log-archive-444455556666/"])
      ]) && anytrue([for f in s.field_selector : f.field == "readOnly" && toset(f.equals) == toset(["true"])])
    ])
    error_message = "Reads of the log archive must be recorded as S3 data events."
  }

  assert {
    condition = anytrue([
      for s in aws_cloudtrail.organization.advanced_event_selector : s.name == "Watched bucket reads and writes" && anytrue([
        for f in s.field_selector : f.field == "resources.ARN" && toset(f.starts_with) == toset(["arn:aws:s3:::harbor-goods-tfstate-111122223333/"])
      ])
    ])
    error_message = "Every read and write of a watched bucket must be recorded."
  }

  assert {
    condition = anytrue([
      for s in aws_cloudtrail.organization.advanced_event_selector : anytrue([
        for f in s.field_selector : f.field == "eventCategory" && toset(f.equals) == toset(["Management"])
      ])
    ])
    error_message = "Management events must stay on."
  }
}

run "rejects_a_wildcard_data_event_bucket" {
  command = plan

  variables {
    data_event_bucket_arns = ["arn:aws:s3:::*"]
  }

  expect_failures = [var.data_event_bucket_arns]
}
