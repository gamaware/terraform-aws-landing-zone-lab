output "log_bucket_name" {
  description = "Central log bucket created by the test."
  value       = module.log_archive.bucket_name
}

output "vpc_id" {
  description = "VPC created by the test."
  value       = module.network.vpc_id
}

output "role_name" {
  description = "Pipeline role created by the test."
  value       = "lz-live-${var.suffix}"
}
