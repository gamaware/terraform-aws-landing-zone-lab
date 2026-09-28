locals {
  stack = "pipeline-role"
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "EcsUpdateService"
    actions   = ["ecs:DescribeServices", "ecs:UpdateService"]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:service/storefront/*"]
  }

  # These actions do not support resource-level permissions.
  statement {
    sid       = "EcsTaskDefinitions"
    actions   = ["ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:aws:ecr:${var.region}:${var.account_id}:repository/storefront"]
  }

  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${var.account_id}:role/storefront-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

module "pipeline_role" {
  source = "../../../../modules/pipeline-role"

  role_name          = "github-actions-deploy"
  github_subjects    = var.github_subjects
  deploy_policy_json = data.aws_iam_policy_document.deploy.json
  passable_role_arns = ["arn:aws:iam::${var.account_id}:role/storefront-*"]
  pass_role_services = ["ecs-tasks.amazonaws.com"]
}
