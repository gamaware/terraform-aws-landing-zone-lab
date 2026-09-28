# Offline tests: a mocked AWS provider, no credentials, no API calls.
# They check what the module decides (OU placement, SCP targets, delegation
# and the guard against account deletion), not what AWS does with it.

mock_provider "aws" {
  override_during = plan

  mock_resource "aws_organizations_organization" {
    defaults = {
      id = "o-exampleorgid"
      roots = [{
        id           = "r-examplerootid111"
        arn          = "arn:aws:organizations::111122223333:root/o-exampleorgid/r-examplerootid111"
        name         = "Root"
        policy_types = []
      }]
    }
  }

  mock_resource "aws_organizations_organizational_unit" {
    defaults = {
      id  = "ou-examplerootid111-exampleouid111"
      arn = "arn:aws:organizations::111122223333:ou/o-exampleorgid/ou-examplerootid111-exampleouid111"
    }
  }

  mock_resource "aws_organizations_account" {
    defaults = {
      id = "777788889999"
    }
  }
}

variables {
  accounts = {
    log-archive = { name = "log-archive", email = "aws-log-archive@example.com", ou = "Security" }
    security    = { name = "security", email = "aws-security@example.com", ou = "Security" }
    shared      = { name = "shared", email = "aws-shared@example.com", ou = "Infrastructure" }
    workloads   = { name = "workloads", email = "aws-workloads@example.com", ou = "Workloads" }
  }

  service_control_policies = {
    deny-leave-organization = {
      file        = "../../policies/scp/deny-leave-organization.json"
      description = "test"
      targets     = ["Root"]
    }
    restrict-regions = {
      file        = "../../policies/scp/restrict-regions.json"
      description = "test"
      targets     = ["Infrastructure", "Workloads"]
    }
  }
}

run "creates_ous_accounts_and_attachments" {
  command = plan

  assert {
    condition     = aws_organizations_organization.this.feature_set == "ALL"
    error_message = "SCPs need the ALL feature set."
  }

  assert {
    condition     = contains(aws_organizations_organization.this.enabled_policy_types, "SERVICE_CONTROL_POLICY")
    error_message = "SCP policy type must be enabled."
  }

  assert {
    condition     = toset(keys(aws_organizations_organizational_unit.this)) == toset(["Security", "Infrastructure", "Workloads"])
    error_message = "Expected the Security, Infrastructure and Workloads OUs."
  }

  assert {
    condition     = length(aws_organizations_account.this) == 4
    error_message = "Expected four member accounts."
  }

  assert {
    condition     = alltrue([for a in aws_organizations_account.this : a.close_on_deletion == false && a.iam_user_access_to_billing == "DENY"])
    error_message = "Accounts must not close on deletion and must deny IAM users billing access."
  }

  assert {
    condition = toset(keys(aws_organizations_policy_attachment.scp)) == toset([
      "deny-leave-organization/Root",
      "restrict-regions/Infrastructure",
      "restrict-regions/Workloads",
    ])
    error_message = "Region restriction must target only Infrastructure and Workloads; leave-org denial targets the root."
  }

  assert {
    condition     = aws_organizations_policy.scp["restrict-regions"].type == "SERVICE_CONTROL_POLICY"
    error_message = "Policies must be SCPs."
  }

  assert {
    condition     = jsondecode(aws_organizations_policy.scp["deny-leave-organization"].content).Statement[0].Action == "organizations:LeaveOrganization"
    error_message = "Policy content must be read from the JSON file unchanged."
  }
}

run "delegates_security_services_to_the_security_account" {
  command = plan

  assert {
    condition     = aws_guardduty_detector.management.enable && aws_securityhub_account.management.enable_default_standards == false
    error_message = "GuardDuty and Security Hub must be on in the management account before delegation."
  }

  assert {
    condition     = aws_guardduty_organization_admin_account.this.admin_account_id == aws_organizations_account.this["security"].id
    error_message = "GuardDuty must be delegated to the security account."
  }

  assert {
    condition     = aws_securityhub_organization_admin_account.this.admin_account_id == aws_organizations_account.this["security"].id
    error_message = "Security Hub must be delegated to the security account."
  }

  assert {
    condition     = aws_organizations_delegated_administrator.config.service_principal == "config.amazonaws.com"
    error_message = "AWS Config must be delegated to the security account."
  }

  assert {
    condition     = aws_organizations_policy_attachment.scp["deny-leave-organization/Root"].target_id == "r-examplerootid111"
    error_message = "Root-targeted SCPs must attach to the organization root ID."
  }

  assert {
    condition     = output.policy_attachments == tolist(["deny-leave-organization/Root", "restrict-regions/Infrastructure", "restrict-regions/Workloads"])
    error_message = "The attachment list output must be sorted and complete."
  }
}

run "rejects_account_in_unknown_ou" {
  command = plan

  variables {
    accounts = {
      security = { name = "security", email = "aws-security@example.com", ou = "Sandbox" }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_duplicate_root_emails" {
  command = plan

  variables {
    accounts = {
      security  = { name = "security", email = "aws@example.com", ou = "Security" }
      workloads = { name = "workloads", email = "AWS@example.com", ou = "Workloads" }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_missing_security_account" {
  command = plan

  variables {
    accounts = {
      workloads = { name = "workloads", email = "aws-workloads@example.com", ou = "Workloads" }
    }
  }

  expect_failures = [var.security_account_key]
}
