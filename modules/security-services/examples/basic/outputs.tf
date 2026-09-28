output "config_aggregator_arn" {
  description = "Organization AWS Config aggregator."
  value       = module.security_services.config_aggregator_arn
}
