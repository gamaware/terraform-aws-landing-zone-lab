# Organization trail module

Runs in the management account. Creates one multi-region organization trail with log file validation, delivered to the
log-archive bucket and encrypted with its key, plus an encrypted CloudWatch Logs copy and a delivery SNS topic.

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
| [aws_cloudtrail.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.trail_to_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.trail_to_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_key.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_sns_topic.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.log_group_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trail_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trail_to_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| log\_bucket\_name | Central log bucket in the log-archive account. | `string` | n/a | yes |
| log\_kms\_key\_arn | KMS key in the log-archive account that encrypts trail log files. | `string` | n/a | yes |
| log\_group\_name | CloudWatch Logs group that receives a copy of the trail in the management account. | `string` | `"/aws/cloudtrail/organization-trail"` | no |
| log\_group\_retention\_days | Retention of the CloudWatch Logs copy. The S3 archive is the long-term record. | `number` | `365` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |
| trail\_name | Name of the organization trail. The log-archive bucket policy trusts this exact name. | `string` | `"organization-trail"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| log\_group\_name | CloudWatch Logs group with the management-account copy of the trail. |
| sns\_topic\_arn | SNS topic notified on each log file delivery. |
| trail\_arn | ARN of the organization trail. |
<!-- END_TF_DOCS -->
