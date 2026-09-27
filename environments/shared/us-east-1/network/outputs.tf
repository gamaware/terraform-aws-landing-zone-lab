output "vpc_id" {
  description = "Shared VPC ID."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets shared with the Workloads OU."
  value       = module.network.private_subnet_ids
}
