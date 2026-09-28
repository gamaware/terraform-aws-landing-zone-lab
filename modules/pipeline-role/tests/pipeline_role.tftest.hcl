# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "555555555555"
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

  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::555555555555:oidc-provider/token.actions.githubusercontent.com"
    }
  }
}

variables {
  github_subjects = ["repo:harbor-goods/storefront:environment:production"]
}

run "exact_trust_and_boundary" {
  command = plan

  assert {
    condition = anytrue([
      for c in one(data.aws_iam_policy_document.trust.statement).condition :
      c.test == "StringEquals" && c.variable == "token.actions.githubusercontent.com:sub" && toset(c.values) == toset(["repo:harbor-goods/storefront:environment:production"])
    ])
    error_message = "The subject must be matched exactly with StringEquals."
  }

  assert {
    condition = anytrue([
      for c in one(data.aws_iam_policy_document.trust.statement).condition :
      c.variable == "token.actions.githubusercontent.com:aud" && toset(c.values) == toset(["sts.amazonaws.com"])
    ])
    error_message = "The audience must be sts.amazonaws.com."
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 1
    error_message = "The provider is created when no existing ARN is given."
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 3600
    error_message = "Pipeline sessions last at most one hour."
  }

  assert {
    condition     = anytrue([for s in data.aws_iam_policy_document.boundary.statement : s.sid == "DenyGovernanceAndAudit" && contains(s.actions, "organizations:*") && contains(s.actions, "iam:CreateAccessKey")])
    error_message = "The boundary must deny organization changes and access key creation."
  }

  assert {
    condition     = length(aws_iam_role_policy.deploy) == 0
    error_message = "No deploy policy unless one is given."
  }
}

run "reuses_existing_provider" {
  command = plan

  variables {
    oidc_provider_arn = "arn:aws:iam::555555555555:oidc-provider/token.actions.githubusercontent.com"
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "An existing provider must not be recreated."
  }

  assert {
    condition     = output.oidc_provider_arn == "arn:aws:iam::555555555555:oidc-provider/token.actions.githubusercontent.com"
    error_message = "The role must trust the given provider."
  }
}

run "rejects_wildcard_subject" {
  command = plan

  variables {
    github_subjects = ["repo:harbor-goods/storefront:*"]
  }

  expect_failures = [var.github_subjects]
}

run "rejects_pull_request_subject" {
  command = plan

  variables {
    github_subjects = ["repo:harbor-goods/storefront:pull_request"]
  }

  expect_failures = [var.github_subjects]
}

run "pass_role_is_scoped" {
  command = plan

  variables {
    passable_role_arns = ["arn:aws:iam::555555555555:role/storefront-*"]
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.boundary.statement :
      s.sid == "AllowPassWorkloadRoles" && toset(s.resources) == toset(["arn:aws:iam::555555555555:role/storefront-*"]) &&
      anytrue([for c in s.condition : c.variable == "iam:PassedToService" && toset(c.values) == toset(["ecs-tasks.amazonaws.com"])])
    ])
    error_message = "PassRole must be limited to named roles and services."
  }

  assert {
    condition     = !anytrue([for s in data.aws_iam_policy_document.boundary.statement : contains(coalesce(s.actions, []), "iam:PassRole") && s.sid != "AllowPassWorkloadRoles"])
    error_message = "No other boundary statement may allow iam:PassRole."
  }
}

run "rejects_pass_role_in_allowed_actions" {
  command = plan

  variables {
    allowed_actions = ["ecs:*", "iam:PassRole"]
  }

  expect_failures = [var.allowed_actions]
}

run "rejects_any_role_pass" {
  command = plan

  variables {
    passable_role_arns = ["arn:aws:iam::555555555555:role/*"]
  }

  expect_failures = [var.passable_role_arns]
}

run "rejects_admin_boundary" {
  command = plan

  variables {
    allowed_actions = ["*"]
  }

  expect_failures = [var.allowed_actions]
}

run "s3_is_limited_to_named_buckets" {
  command = plan

  variables {
    s3_bucket_arns = ["arn:aws:s3:::harbor-goods-tfstate-111122223333"]
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.boundary.statement :
      s.sid == "AllowNamedBuckets" && toset(s.resources) == toset(["arn:aws:s3:::harbor-goods-tfstate-111122223333", "arn:aws:s3:::harbor-goods-tfstate-111122223333/*"])
    ])
    error_message = "S3 actions must be scoped to the named buckets and their objects."
  }

  assert {
    condition     = !anytrue([for s in data.aws_iam_policy_document.boundary.statement : anytrue([for a in coalesce(s.actions, []) : a == "s3:*" || (startswith(a, "s3:") && s.sid != "AllowNamedBuckets")]) if s.effect != "Deny"])
    error_message = "No allow statement may grant s3:* or S3 actions outside the named buckets."
  }
}

run "rejects_s3_in_allowed_actions" {
  command = plan

  variables {
    allowed_actions = ["ecs:*", "s3:*"]
  }

  expect_failures = [var.allowed_actions]
}

run "rejects_wildcard_bucket" {
  command = plan

  variables {
    s3_bucket_arns = ["arn:aws:s3:::*"]
  }

  expect_failures = [var.s3_bucket_arns]
}

run "rejects_admin_boundary_in_any_case" {
  command = plan

  variables {
    allowed_actions = ["ecs:*", "IAM:*"]
  }

  expect_failures = [var.allowed_actions]
}

run "rejects_service_wildcard" {
  command = plan

  variables {
    allowed_actions = ["*:*"]
  }

  expect_failures = [var.allowed_actions]
}

run "rejects_iam_action_wildcard" {
  command = plan

  variables {
    allowed_actions = ["ecs:*", "iam:*Role*"]
  }

  expect_failures = [var.allowed_actions]
}
