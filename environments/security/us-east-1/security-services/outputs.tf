output "guardduty_detector_id" {
  description = "GuardDuty detector in the delegated administrator account."
  value       = module.security_services.guardduty_detector_id
}

output "config_aggregator_arn" {
  description = "Organization AWS Config aggregator."
  value       = module.security_services.config_aggregator_arn
}
