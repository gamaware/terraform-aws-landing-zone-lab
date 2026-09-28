output "id" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.id
}

output "arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "kms_key_arn" {
  description = "KMS key that encrypts the bucket."
  value       = one(one(aws_s3_bucket_server_side_encryption_configuration.kms.rule).apply_server_side_encryption_by_default).kms_master_key_id
}
