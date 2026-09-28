output "guardduty_detector_id" {
  description = "GuardDuty detector in the delegated administrator account."
  value       = aws_guardduty_detector.this.id
}

output "securityhub_standards_arns" {
  description = "Security Hub standards this account is subscribed to."
  value       = [for s in aws_securityhub_standards_subscription.this : s.standards_arn]
}

output "config_aggregator_arn" {
  description = "Organization AWS Config aggregator."
  value       = aws_config_configuration_aggregator.organization.arn
}
