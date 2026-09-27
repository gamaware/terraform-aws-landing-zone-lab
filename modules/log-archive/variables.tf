variable "bucket_name" {
  description = "Name of the central log bucket. The access-log bucket takes the same name with an -access suffix."
  type        = string
}

variable "organization_id" {
  description = "AWS Organizations ID, for example o-exampleorgid. Scopes AWS Config writes and auditor reads to the organization."
  type        = string

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "organization_id must look like o-exampleorgid (o- followed by 10-32 lowercase letters or digits)."
  }
}

variable "management_account_id" {
  description = "Management account that owns the organization trail."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "trail_name" {
  description = "Name of the organization trail allowed to write to the bucket."
  type        = string
  default     = "organization-trail"
}

variable "management_access_role_name" {
  description = "Role that deploys this stack. It is the only principal allowed to delete log objects or change lifecycle rules."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "deny_object_deletion" {
  description = "Deny object deletion and bucket policy, versioning and lifecycle changes to everyone except the management access role. Only the live test turns this off."
  type        = bool
  default     = true
}

variable "log_reader_role_arns" {
  description = "Role ARN patterns in the organization allowed to decrypt logs, for example the security account's audit role."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.log_reader_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.*[A-Za-z0-9].*$", arn)) && !endswith(arn, ":role/*")])
    error_message = "log_reader_role_arns must name roles in a specific account; a wildcard account or role/* would open decryption to the organization."
  }
}

variable "glacier_transition_days" {
  description = "Days before log objects move to S3 Glacier Flexible Retrieval."
  type        = number
  default     = 90
}

variable "log_expiration_days" {
  description = "Days log objects are kept before they expire."
  type        = number
  default     = 400

  validation {
    condition     = var.log_expiration_days >= 365
    error_message = "Keep audit logs for at least 365 days."
  }
}

variable "access_log_expiration_days" {
  description = "Days S3 server access logs are kept."
  type        = number
  default     = 180
}

variable "kms_deletion_window_days" {
  description = "Waiting period before a deleted log key is gone. Logs are unreadable without it, so keep the maximum outside tests."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "kms_deletion_window_days must be between 7 and 30."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets. Only the live test sets this to true."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
