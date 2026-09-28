output "organization_id" {
  description = "Organization ID, copied into the log-archive stack variables."
  value       = module.organization.organization_id
}

output "account_ids" {
  description = "Member account IDs, copied into each member stack's variables."
  value       = module.organization.account_ids
}

output "organizational_unit_arns" {
  description = "OU ARNs, used by the network stack as RAM principals."
  value       = module.organization.organizational_unit_arns
}

output "policy_attachments" {
  description = "SCP attachments as policy/target."
  value       = module.organization.policy_attachments
}
