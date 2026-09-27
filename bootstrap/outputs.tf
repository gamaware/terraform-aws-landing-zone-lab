output "state_bucket_name" {
  description = "Bucket to set in backend.hcl."
  value       = module.state.id
}

output "state_kms_key_arn" {
  description = "KMS key that encrypts state objects."
  value       = aws_kms_key.state.arn
}
