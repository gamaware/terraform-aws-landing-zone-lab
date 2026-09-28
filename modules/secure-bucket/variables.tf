variable "name" {
  description = "Globally unique bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.name))
    error_message = "Bucket names must be 3-63 characters of lowercase letters, digits, dots and hyphens."
  }
}

variable "kms_key_arn" {
  description = "Customer managed KMS key that encrypts every object (SSE-KMS with a bucket key)."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN."
  }
}

variable "additional_policy_json" {
  description = "Extra bucket policy statements merged with the TLS-only statement, for example service write access."
  type        = string
  default     = null
}

variable "glacier_transition_days" {
  description = "Days before current objects move to S3 Glacier Flexible Retrieval. Null disables the transition."
  type        = number
  default     = null
}

variable "expiration_days" {
  description = "Days before current objects expire. Null keeps objects until removed by hand."
  type        = number
  default     = null

  validation {
    condition     = var.expiration_days == null || try(var.expiration_days >= 1, false)
    error_message = "expiration_days must be null or at least 1."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days a noncurrent object version is kept before it expires."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Allow Terraform to delete a non-empty bucket. Only the live test sets this to true."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}
