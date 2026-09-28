output "role_arn" {
  description = "ARN to set as role-to-assume in the GitHub Actions workflow."
  value       = aws_iam_role.this.arn
}

output "boundary_policy_arn" {
  description = "Permissions boundary attached to the role."
  value       = aws_iam_policy.boundary.arn
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider the role trusts."
  value       = local.oidc_provider_arn
}
