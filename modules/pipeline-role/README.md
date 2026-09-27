# Pipeline role module

Runs in a workload account. Creates the GitHub OIDC provider (or reuses one) and a deploy role whose trust matches exact
repository subjects, capped by a permissions boundary that blocks identity, organization and audit changes.

Usage: [examples/basic](examples/basic/main.tf). Offline tests: [tests/](tests/) (`terraform test`, mocked provider).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10.0 |
| aws | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.0, < 7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| github\_subjects | Exact OIDC subjects allowed to assume the role, for example repo:harbor-goods/storefront:environment:production. | `list(string)` | n/a | yes |
| allowed\_actions | Actions the permissions boundary allows. The deploy policy grants a subset; the boundary is the ceiling. | `list(string)` | ```[ "application-autoscaling:*", "cloudwatch:*", "ecr:*", "ecs:*", "elasticloadbalancing:*", "iam:GetRole", "lambda:*", "logs:*", "s3:*", "ssm:GetParameter*" ]``` | no |
| deploy\_policy\_json | Inline policy with the permissions the pipeline actually needs. Null leaves the role with no permissions. | `string` | `null` | no |
| max\_session\_duration | Maximum session length in seconds. | `number` | `3600` | no |
| oidc\_provider\_arn | Existing GitHub OIDC provider in the account. Null creates one; an account can hold only one per URL. | `string` | `null` | no |
| pass\_role\_services | Services the pipeline may pass those roles to. | `list(string)` | ```[ "ecs-tasks.amazonaws.com" ]``` | no |
| passable\_role\_arns | Role ARNs (or ARN patterns) the pipeline may pass, for example task execution roles of the workload. | `list(string)` | `[]` | no |
| role\_name | Name of the deploy role. The boundary policy is named <role\_name>-boundary. | `string` | `"github-actions-deploy"` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| boundary\_policy\_arn | Permissions boundary attached to the role. |
| oidc\_provider\_arn | GitHub OIDC provider the role trusts. |
| role\_arn | ARN to set as role-to-assume in the GitHub Actions workflow. |
<!-- END_TF_DOCS -->
