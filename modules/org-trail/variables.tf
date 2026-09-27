variable "trail_name" {
  description = "Name of the organization trail. The log-archive bucket policy trusts this exact name."
  type        = string
  default     = "organization-trail"
}

variable "log_bucket_name" {
  description = "Central log bucket in the log-archive account."
  type        = string
}

variable "log_kms_key_arn" {
  description = "KMS key in the log-archive account that encrypts trail log files."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.log_kms_key_arn))
    error_message = "log_kms_key_arn must be a KMS key ARN, not an alias or key ID, because the key lives in another account."
  }
}

variable "log_group_name" {
  description = "CloudWatch Logs group that receives a copy of the trail in the management account."
  type        = string
  default     = "/aws/cloudtrail/organization-trail"
}

variable "log_group_retention_days" {
  description = "Retention of the CloudWatch Logs copy. The S3 archive is the long-term record."
  type        = number
  default     = 365

  validation {
    condition     = contains([365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_group_retention_days)
    error_message = "log_group_retention_days must be a CloudWatch Logs retention value of at least 365 days."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
