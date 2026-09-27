output "permission_set_arns" {
  description = "Permission set ARNs keyed by name."
  value       = { for name, ps in aws_ssoadmin_permission_set.this : name => ps.arn }
}

output "assignment_keys" {
  description = "Every assignment as group/permission-set/account, for review in plans."
  value       = sort(keys(local.assignments))
}
