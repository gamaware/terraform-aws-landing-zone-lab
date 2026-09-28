output "vpc_id" {
  description = "Shared VPC ID."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone, the ones shared through RAM."
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDRs keyed by availability zone."
  value       = local.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone (empty when nat_gateway_mode is none)."
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "nat_gateway_count" {
  description = "Number of NAT gateways, the main fixed cost of this module."
  value       = length(local.nat_azs)
}

output "resource_share_arn" {
  description = "RAM share for the private subnets, or null when nothing is shared."
  value       = try(aws_ram_resource_share.private_subnets[0].arn, null)
}
