output "bucket_name" {
  description = "Central log bucket name, used by the organization trail and every AWS Config delivery channel."
  value       = module.logs.id
}

output "bucket_arn" {
  description = "Central log bucket ARN."
  value       = module.logs.arn
}

output "access_log_bucket_name" {
  description = "Bucket that stores S3 server access logs for the central log bucket."
  value       = module.access_logs.id
}

output "kms_key_arn" {
  description = "KMS key that encrypts the log archive."
  value       = aws_kms_key.logs.arn
}
