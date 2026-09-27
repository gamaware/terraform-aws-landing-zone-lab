output "budget_names" {
  description = "Names of the budgets created."
  value       = sort(keys(aws_budgets_budget.this))
}

output "total_monthly_limit_usd" {
  description = "Sum of the per-account budget limits, to compare with the organization-wide budget."
  value       = sum(concat([0], [for b in values(var.budgets) : b.limit_usd if b.account_id != null]))
}
