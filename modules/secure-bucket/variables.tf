variable "name" {
  description = "Globally unique bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.name))
    error_message = "Bucket names must be 3-63 characters of lowercase letters, digits, dots and hyphens."
  }
}

variable "sse_algorithm" {
  description = "aws:kms (default) or AES256. Use AES256 only for an S3 server access log target, which cannot use SSE-KMS."
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["aws:kms", "AES256"], var.sse_algorithm)
    error_message = "sse_algorithm must be aws:kms or AES256."
  }
}

variable "kms_key_arn" {
  description = "KMS key used when sse_algorithm is aws:kms."
  type        = string
  default     = null

  validation {
    condition     = var.sse_algorithm != "aws:kms" || var.kms_key_arn != null
    error_message = "kms_key_arn is required when sse_algorithm is aws:kms."
  }
}

variable "access_log_bucket" {
  description = "Bucket that receives S3 server access logs. Pass a name known at plan time, not another resource's id. Null only for the access-log bucket itself."
  type        = string
  default     = null
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
