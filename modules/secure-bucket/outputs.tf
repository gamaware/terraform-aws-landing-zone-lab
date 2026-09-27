output "id" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.id
}

output "arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "encryption" {
  description = "Server-side encryption mode applied to the bucket: aws:kms or AES256."
  value       = local.use_kms ? "aws:kms" : "AES256"
}
