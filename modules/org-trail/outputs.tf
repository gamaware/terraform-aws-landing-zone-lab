output "trail_arn" {
  description = "ARN of the organization trail."
  value       = aws_cloudtrail.organization.arn
}

output "log_group_name" {
  description = "CloudWatch Logs group with the management-account copy of the trail."
  value       = aws_cloudwatch_log_group.trail.name
}

output "sns_topic_arn" {
  description = "SNS topic notified on each log file delivery."
  value       = aws_sns_topic.trail.arn
}
