output "permission_set_arns" {
  description = "Permission set ARNs keyed by name."
  value       = module.identity_center.permission_set_arns
}
