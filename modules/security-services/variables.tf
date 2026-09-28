variable "guardduty_finding_frequency" {
  description = "How often GuardDuty publishes updated findings."
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.guardduty_finding_frequency)
    error_message = "guardduty_finding_frequency must be FIFTEEN_MINUTES, ONE_HOUR or SIX_HOURS."
  }
}

variable "guardduty_features" {
  description = "GuardDuty protection plans auto-enabled for every member account."
  type        = list(string)
  default     = ["S3_DATA_EVENTS", "EBS_MALWARE_PROTECTION"]
}

variable "securityhub_standards" {
  description = "Security Hub standards, as the path after standards/ in the standard ARN."
  type        = list(string)
  default = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "cis-aws-foundations-benchmark/v/3.0.0",
  ]
}

variable "tags" {
  description = "Tags applied to every resource that supports them."
  type        = map(string)
  default     = {}
}
