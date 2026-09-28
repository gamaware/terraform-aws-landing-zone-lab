# Config recorder module

Runs in every member account. Records all supported resource types (global ones in the home region only) and delivers to
the central log-archive bucket.

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
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_service_linked_role.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| delivery\_bucket\_name | Central log-archive bucket that receives configuration snapshots and history. | `string` | n/a | yes |
| delivery\_kms\_key\_arn | KMS key in the log-archive account used to encrypt AWS Config deliveries. | `string` | n/a | yes |
| create\_service\_linked\_role | Create the AWS Config service-linked role. Set false where it already exists. | `bool` | `true` | no |
| record\_global\_resources | Record IAM and other global resources. Set true in exactly one region per account to avoid duplicates. | `bool` | `true` | no |
| recording\_frequency | CONTINUOUS for every change, DAILY to cut cost in non-production accounts. | `string` | `"CONTINUOUS"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| recorder\_name | Name of the AWS Config recorder. |
| recording\_global\_resources | Whether this recorder records global resource types. |
<!-- END_TF_DOCS -->
