# Log archive module

Runs in the log-archive account. Creates the KMS key and the central bucket that receive the organization CloudTrail and
every account's AWS Config delivery. The organization trail records reads of the bucket as S3 data events
([ADR 0007](../../docs/adr/0007-s3-data-events-instead-of-server-access-logs.md)). Service writes are pinned to the
management account's trail and to the organization ID; object deletion is denied to everyone except the management
access role.

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

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| logs | ../secure-bucket | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kms_alias.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bucket\_name | Name of the central log bucket. | `string` | n/a | yes |
| management\_account\_id | Management account that owns the organization trail. | `string` | n/a | yes |
| organization\_id | AWS Organizations ID, for example o-exampleorgid. Scopes AWS Config writes and auditor reads to the organization. | `string` | n/a | yes |
| deny\_object\_deletion | Deny object deletion and bucket policy, versioning and lifecycle changes to everyone except the management access role. Only the live test turns this off. | `bool` | `true` | no |
| force\_destroy | Allow Terraform to delete non-empty buckets. Only the live test sets this to true. | `bool` | `false` | no |
| glacier\_transition\_days | Days before log objects move to S3 Glacier Flexible Retrieval. | `number` | `90` | no |
| kms\_deletion\_window\_days | Waiting period before a deleted log key is gone. Logs are unreadable without it, so keep the maximum outside tests. | `number` | `30` | no |
| log\_expiration\_days | Days log objects are kept before they expire. | `number` | `400` | no |
| log\_reader\_role\_arns | Role ARN patterns in the organization allowed to decrypt logs, for example the security account's audit role. | `list(string)` | `[]` | no |
| management\_access\_role\_name | Role that deploys this stack. It is the only principal allowed to delete log objects or change lifecycle rules. | `string` | `"OrganizationAccountAccessRole"` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |
| trail\_name | Name of the organization trail allowed to write to the bucket. | `string` | `"organization-trail"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| bucket\_arn | Central log bucket ARN. |
| bucket\_name | Central log bucket name, used by the organization trail and every AWS Config delivery channel. |
| kms\_key\_arn | KMS key that encrypts the log archive. |
<!-- END_TF_DOCS -->
