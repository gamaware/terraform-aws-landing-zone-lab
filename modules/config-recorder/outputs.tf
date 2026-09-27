output "recorder_name" {
  description = "Name of the AWS Config recorder."
  value       = aws_config_configuration_recorder.this.name
}

output "recording_global_resources" {
  description = "Whether this recorder records global resource types."
  value       = var.record_global_resources
}
