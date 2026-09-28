# Secure bucket module

One hardened S3 bucket pattern: SSE-KMS with a customer managed key and bucket keys, versioning, all four public access
block settings, ACLs disabled, a TLS-only bucket policy and lifecycle retention. The log archive and the state bootstrap
both use it, so a fix lands once. Object reads and writes are recorded as CloudTrail S3 data events by the organization
trail instead of S3 server access logs, whose target bucket cannot use SSE-KMS
([ADR 0007](../../docs/adr/0007-s3-data-events-instead-of-server-access-logs.md)).

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
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| kms\_key\_arn | Customer managed KMS key that encrypts every object (SSE-KMS with a bucket key). | `string` | n/a | yes |
| name | Globally unique bucket name. | `string` | n/a | yes |
| additional\_policy\_json | Extra bucket policy statements merged with the TLS-only statement, for example service write access. | `string` | `null` | no |
| expiration\_days | Days before current objects expire. Null keeps objects until removed by hand. | `number` | `null` | no |
| force\_destroy | Allow Terraform to delete a non-empty bucket. Only the live test sets this to true. | `bool` | `false` | no |
| glacier\_transition\_days | Days before current objects move to S3 Glacier Flexible Retrieval. Null disables the transition. | `number` | `null` | no |
| noncurrent\_version\_expiration\_days | Days a noncurrent object version is kept before it expires. | `number` | `90` | no |
| tags | Tags applied to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | Bucket ARN. |
| id | Bucket name. |
| kms\_key\_arn | KMS key that encrypts the bucket. |
<!-- END_TF_DOCS -->
