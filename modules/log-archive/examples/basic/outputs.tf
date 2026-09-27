output "kms_key_arn" {
  description = "Key that org-trail and config-recorder receive."
  value       = module.log_archive.kms_key_arn
}
