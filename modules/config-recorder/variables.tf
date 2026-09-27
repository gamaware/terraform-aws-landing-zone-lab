variable "delivery_bucket_name" {
  description = "Central log-archive bucket that receives configuration snapshots and history."
  type        = string
}

variable "delivery_kms_key_arn" {
  description = "KMS key in the log-archive account used to encrypt AWS Config deliveries."
  type        = string
}

variable "record_global_resources" {
  description = "Record IAM and other global resources. Set true in exactly one region per account to avoid duplicates."
  type        = bool
  default     = true
}

variable "recording_frequency" {
  description = "CONTINUOUS for every change, DAILY to cut cost in non-production accounts."
  type        = string
  default     = "CONTINUOUS"

  validation {
    condition     = contains(["CONTINUOUS", "DAILY"], var.recording_frequency)
    error_message = "recording_frequency must be CONTINUOUS or DAILY."
  }
}

variable "create_service_linked_role" {
  description = "Create the AWS Config service-linked role. Set false where it already exists."
  type        = bool
  default     = true
}
