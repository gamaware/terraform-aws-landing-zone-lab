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

  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = ["arn:aws:sso:::instance/ssoins-1111111111111111"]
      identity_store_ids = ["d-1111111111"]
    }
  }

  mock_data "aws_identitystore_group" {
    defaults = {
      group_id = "11111111-2222-3333-4444-555555555555"
    }
  }
}

variables {
  permission_sets = {
    PlatformAdmin = {
      description         = "Admin"
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    ReadOnly = {
      description         = "Read only"
      session_duration    = "PT8H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy       = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"s3:GetObject\",\"Resource\":\"*\"}]}"
    }
  }

  assignments = [
    { group = "platform-admins", permission_set = "PlatformAdmin", account_id = "555555555555" },
    { group = "platform-admins", permission_set = "ReadOnly", account_id = "123456789012" },
    { group = "developers", permission_set = "ReadOnly", account_id = "555555555555" },
  ]
}

run "permission_sets_and_assignments" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.this["PlatformAdmin"].session_duration == "PT1H"
    error_message = "Admin sessions default to one hour."
  }

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 2
    error_message = "One managed policy attachment per permission set and policy."
  }

  assert {
    condition     = toset(keys(aws_ssoadmin_permission_set_inline_policy.this)) == toset(["ReadOnly"])
    error_message = "Inline policies are attached only where given."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 3
    error_message = "Each group/permission set/account triple becomes one assignment."
  }

  assert {
    condition     = alltrue([for a in aws_ssoadmin_account_assignment.this : a.principal_type == "GROUP"])
    error_message = "Access is granted to groups, never to individual users."
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 2
    error_message = "Each group is looked up once."
  }
}

run "rejects_long_admin_sessions" {
  command = plan

  variables {
    permission_sets = {
      PlatformAdmin = {
        description         = "Admin"
        session_duration    = "PT8H"
        managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      }
    }
    assignments = []
  }

  expect_failures = [var.permission_sets]
}

run "rejects_assignment_to_undefined_permission_set" {
  command = plan

  variables {
    assignments = [
      { group = "developers", permission_set = "Billing", account_id = "555555555555" },
    ]
  }

  expect_failures = [var.assignments]
}

run "rejects_session_over_twelve_hours" {
  command = plan

  variables {
    permission_sets = {
      ReadOnly = {
        description      = "Read only"
        session_duration = "PT24H"
      }
    }
    assignments = []
  }

  expect_failures = [var.permission_sets]
}
