output "role_arn" {
  description = "Set as role-to-assume in the workload repository's deploy workflow."
  value       = module.pipeline_role.role_arn
}
