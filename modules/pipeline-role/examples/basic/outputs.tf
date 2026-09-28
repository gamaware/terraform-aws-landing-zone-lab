output "role_arn" {
  description = "Role to set as role-to-assume in the workflow."
  value       = module.pipeline_role.role_arn
}
