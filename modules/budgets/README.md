# Budgets module

Runs in the management account. Creates monthly USD cost budgets for the organization and per linked account, with
actual and forecast email alerts.

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
| [aws_budgets_budget.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| budgets | Monthly USD budgets keyed by name. Leave account\_id null for an organization-wide budget; set forecast\_alert = false to skip the forecast notification. | ```map(object({ limit_usd = number account_id = optional(string) actual_thresholds = optional(list(number), [80, 100]) forecast_alert = optional(bool, true) forecast_threshold = optional(number, 100) }))``` | n/a | yes |
| subscriber\_emails | Addresses notified when a threshold is crossed. AWS Budgets allows up to 10 per notification. | `list(string)` | n/a | yes |
| tags | Tags applied to each budget. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| budget\_names | Names of the budgets created. |
| total\_monthly\_limit\_usd | Sum of the per-account budget limits, to compare with the organization-wide budget. |
<!-- END_TF_DOCS -->
