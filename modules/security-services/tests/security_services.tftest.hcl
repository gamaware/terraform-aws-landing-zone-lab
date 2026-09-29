# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "777788889999"
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

run "organization_wide_detection" {
  command = plan

  assert {
    condition     = aws_guardduty_organization_configuration.this.auto_enable_organization_members == "ALL"
    error_message = "GuardDuty must enroll every current and future member."
  }

  assert {
    condition     = toset(keys(aws_guardduty_organization_configuration_feature.this)) == toset(["S3_DATA_EVENTS", "EBS_MALWARE_PROTECTION"])
    error_message = "S3 and malware protection must be auto-enabled."
  }

  assert {
    condition     = aws_securityhub_organization_configuration.this.auto_enable
    error_message = "Security Hub must auto-enable new members."
  }

  assert {
    condition     = contains([for s in aws_securityhub_standards_subscription.this : s.standards_arn], "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0")
    error_message = "The AWS Foundational Security Best Practices standard must be on."
  }

  assert {
    condition     = one(aws_config_configuration_aggregator.organization.organization_aggregation_source).all_regions
    error_message = "The aggregator must read every region."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.config_aggregator.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
    error_message = "The aggregator role needs the AWS managed organizations policy."
  }

  assert {
    condition = anytrue([
      for c in one(data.aws_iam_policy_document.config_assume.statement).condition :
      c.test == "StringEquals" && c.variable == "aws:SourceAccount" && toset(c.values) == toset(["777788889999"])
    ])
    error_message = "The aggregator role must trust AWS Config only on behalf of the security account."
  }
}

run "rejects_unknown_frequency" {
  command = plan

  variables {
    guardduty_finding_frequency = "DAILY"
  }

  expect_failures = [var.guardduty_finding_frequency]
}
