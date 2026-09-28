# Security services module

Runs in the security account after delegation. Enables GuardDuty with organization auto-enrollment and protection plans,
Security Hub with auto-enable and the listed standards, and an organization-wide AWS Config aggregator.

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
| [aws_config_configuration_aggregator.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_guardduty_detector.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_organization_configuration_feature.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_iam_role.config_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.config_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_securityhub_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_securityhub_standards_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |
| [aws_iam_policy_document.config_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| guardduty\_features | GuardDuty protection plans auto-enabled for every member account. | `list(string)` | ```[ "S3_DATA_EVENTS", "EBS_MALWARE_PROTECTION" ]``` | no |
| guardduty\_finding\_frequency | How often GuardDuty publishes updated findings. | `string` | `"FIFTEEN_MINUTES"` | no |
| securityhub\_standards | Security Hub standards, as the path after standards/ in the standard ARN. | `list(string)` | ```[ "aws-foundational-security-best-practices/v/1.0.0", "cis-aws-foundations-benchmark/v/3.0.0" ]``` | no |
| tags | Tags applied to every resource that supports them. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| config\_aggregator\_arn | Organization AWS Config aggregator. |
| guardduty\_detector\_id | GuardDuty detector in the delegated administrator account. |
| securityhub\_standards\_arns | Security Hub standards this account is subscribed to. |
<!-- END_TF_DOCS -->
