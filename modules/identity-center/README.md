# Identity Center module

Runs in the management account. Creates IAM Identity Center permission sets and assigns them to groups per account.
Validations cap sessions at 12 hours and keep AdministratorAccess sessions at one hour.

Usage: [examples/basic](examples/basic/main.tf). Offline tests: [tests/](tests/) (`terraform test`, mocked provider).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0, < 2.0.0 |
| aws | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.0, < 7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ssoadmin_account_assignment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_ssoadmin_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_permission_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set) | resource |
| [aws_ssoadmin_permission_set_inline_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy) | resource |
| [aws_identitystore_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/identitystore_group) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| permission\_sets | Permission sets keyed by name. session\_duration is ISO 8601, from PT1H to PT12H. | ```map(object({ description = string session_duration = optional(string, "PT1H") managed_policy_arns = optional(list(string), []) inline_policy = optional(string) }))``` | n/a | yes |
| assignments | Group-to-account assignments. group is the Identity Center group display name. | ```list(object({ group = string permission_set = string account_id = string }))``` | `[]` | no |
| tags | Tags applied to permission sets. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| assignment\_keys | Every assignment as group/permission-set/account, for review in plans. |
| permission\_set\_arns | Permission set ARNs keyed by name. |
<!-- END_TF_DOCS -->
