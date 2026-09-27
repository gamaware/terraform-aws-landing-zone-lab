output "permission_set_arns" {
  description = "Permission set ARNs keyed by name."
  value       = module.identity_center.permission_set_arns
}

output "assignment_keys" {
  description = "Group/permission-set/account assignments."
  value       = module.identity_center.assignment_keys
}
