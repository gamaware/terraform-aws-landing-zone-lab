output "config_recorder_name" {
  description = "AWS Config recorder in this account."
  value       = module.config_recorder.recorder_name
}
