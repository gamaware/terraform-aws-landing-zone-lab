# Deploy role for CI in a workload account. GitHub Actions exchanges its OIDC
# token for short-lived credentials: no access keys are stored anywhere. The
# trust policy matches exact repository and environment subjects, and a
# permissions boundary caps what the role can ever be granted.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  oidc_provider_arn = var.oidc_provider_arn != null ? var.oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.oidc_provider_arn == null ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # StringEquals, never StringLike: a wildcard subject would let any branch
    # or fork workflow in the repository assume the role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github_subjects
    }
  }
}

# The boundary is the ceiling. Even if someone later attaches
# AdministratorAccess to the role, it cannot touch identity, the organization
# or the audit trail.
data "aws_iam_policy_document" "boundary" {
  #checkov:skip=CKV_AWS_111:Permissions boundary: it grants nothing alone; the deploy policy grants scoped permissions inside this ceiling.
  #checkov:skip=CKV_AWS_356:Permissions boundary: the ceiling is set per service; resources are scoped in the deploy policy.
  statement {
    sid       = "AllowWorkloadServices"
    actions   = var.allowed_actions
    resources = ["*"]
  }

  # PassRole is the usual boundary escape: with lambda:* or ecs:* the pipeline
  # could run code as any role in the account. Only named roles, only to the
  # listed services.
  dynamic "statement" {
    for_each = length(var.passable_role_arns) > 0 ? [1] : []

    content {
      sid       = "AllowPassWorkloadRoles"
      actions   = ["iam:PassRole"]
      resources = var.passable_role_arns

      condition {
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = var.pass_role_services
      }
    }
  }

  statement {
    sid    = "DenyGovernanceAndAudit"
    effect = "Deny"
    actions = [
      "account:*",
      "organizations:*",
      "cloudtrail:DeleteTrail",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
      "config:DeleteConfigurationRecorder",
      "config:StopConfigurationRecorder",
      "guardduty:DeleteDetector",
      "securityhub:DisableSecurityHub",
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteUserPermissionsBoundary",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyBoundaryTampering"
    effect    = "Deny"
    actions   = ["iam:CreatePolicyVersion", "iam:DeletePolicy", "iam:DeletePolicyVersion", "iam:SetDefaultPolicyVersion"]
    resources = ["arn:${local.partition}:iam::${local.account_id}:policy/${var.role_name}-boundary"]
  }

  statement {
    sid       = "DenyRolesWithoutBoundary"
    effect    = "Deny"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:${local.partition}:iam::${local.account_id}:policy/${var.role_name}-boundary"]
    }
  }
}

resource "aws_iam_policy" "boundary" {
  name        = "${var.role_name}-boundary"
  description = "Permissions boundary for ${var.role_name} and any role it creates."
  policy      = data.aws_iam_policy_document.boundary.json
  tags        = var.tags
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions through OIDC to deploy workloads."
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = aws_iam_policy.boundary.arn
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

resource "aws_iam_role_policy" "deploy" {
  count = var.deploy_policy_json == null ? 0 : 1

  name   = "deploy"
  role   = aws_iam_role.this.id
  policy = var.deploy_policy_json
}
