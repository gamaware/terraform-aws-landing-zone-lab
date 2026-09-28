output "organization_id" {
  description = "Organization ID."
  value       = aws_organizations_organization.this.id
}

output "root_id" {
  description = "ID of the organization root."
  value       = local.root_id
}

output "organizational_unit_ids" {
  description = "OU IDs keyed by OU name."
  value       = { for name, ou in aws_organizations_organizational_unit.this : name => ou.id }
}

output "organizational_unit_arns" {
  description = "OU ARNs keyed by OU name, used as RAM principals."
  value       = { for name, ou in aws_organizations_organizational_unit.this : name => ou.arn }
}

output "account_ids" {
  description = "Member account IDs keyed by account key."
  value       = { for key, account in aws_organizations_account.this : key => account.id }
}

output "policy_attachments" {
  description = "Every SCP attachment as policy/target, for review in plans."
  value       = sort(keys(local.policy_attachments))
}
