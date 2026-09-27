output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = module.network.private_subnet_ids
}
