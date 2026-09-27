# Organization module

Runs in the management account. Creates AWS Organizations with the ALL feature set, the Security, Infrastructure and
Workloads OUs, member accounts, service control policies read from `policies/scp/`, and the delegated administrators for
GuardDuty, Security Hub and AWS Config. Accounts carry `prevent_destroy`.

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
| [aws_guardduty_detector.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_delegated_administrator.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_policy.scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_ram_sharing_with_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_sharing_with_organization) | resource |
| [aws_securityhub_account.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| accounts | Member accounts keyed by a short stable key. ou must be one of organizational\_units. | ```map(object({ name = string email = string ou = string }))``` | n/a | yes |
| cross\_account\_role\_name | Role Organizations creates in each new account, trusted by the management account. | `string` | `"OrganizationAccountAccessRole"` | no |
| enable\_ram\_sharing | Let AWS RAM share resources, such as the shared VPC subnets, with the whole organization. | `bool` | `true` | no |
| organizational\_units | OUs created directly under the root. | `list(string)` | ```[ "Security", "Infrastructure", "Workloads" ]``` | no |
| security\_account\_key | Key in accounts for the account that becomes delegated administrator for GuardDuty, Security Hub and AWS Config. | `string` | `"security"` | no |
| service\_access\_principals | AWS services given trusted access to the organization. | `list(string)` | ```[ "cloudtrail.amazonaws.com", "config.amazonaws.com", "config-multiaccountsetup.amazonaws.com", "guardduty.amazonaws.com", "malware-protection.guardduty.amazonaws.com", "ram.amazonaws.com", "securityhub.amazonaws.com", "sso.amazonaws.com" ]``` | no |
| service\_control\_policies | SCPs keyed by name: the JSON file, a description and the targets (Root or OU names). | ```map(object({ file = string description = string targets = list(string) }))``` | `{}` | no |
| tags | Tags applied to OUs, accounts and policies. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| account\_ids | Member account IDs keyed by account key. |
| organization\_id | Organization ID. |
| organizational\_unit\_arns | OU ARNs keyed by OU name, used as RAM principals. |
| organizational\_unit\_ids | OU IDs keyed by OU name. |
| policy\_attachments | Every SCP attachment as policy/target, for review in plans. |
| root\_id | ID of the organization root. |
<!-- END_TF_DOCS -->
