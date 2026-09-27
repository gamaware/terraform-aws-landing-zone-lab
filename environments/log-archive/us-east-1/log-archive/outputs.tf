output "bucket_name" {
  description = "Central log bucket, set in the org-trail and baseline stacks."
  value       = module.log_archive.bucket_name
}

output "kms_key_arn" {
  description = "Log archive KMS key, set in the org-trail and baseline stacks."
  value       = module.log_archive.kms_key_arn
}
