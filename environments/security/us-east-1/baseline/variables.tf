variable "region" {
  description = "Region this stack deploys to."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "Account this stack deploys to. The provider refuses any other."
  type        = string
}

variable "management_access_role_name" {
  description = "Role assumed in the member account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "tags" {
  description = "Default tags for every resource."
  type        = map(string)
  default = {
    Project   = "landing-zone"
    Owner     = "platform"
    ManagedBy = "terraform"
  }
}

variable "log_bucket_name" {
  description = "Central log bucket, from the log-archive stack output."
  type        = string
}

variable "log_kms_key_arn" {
  description = "Log archive KMS key, from the log-archive stack output."
  type        = string
}

variable "recording_frequency" {
  description = "AWS Config recording frequency for this account."
  type        = string
  default     = "CONTINUOUS"
}
