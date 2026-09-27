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

variable "bucket_name" {
  description = "Central log bucket name."
  type        = string
}

variable "organization_id" {
  description = "Organization ID, from the organization stack output."
  type        = string
}

variable "management_account_id" {
  description = "Management account that owns the organization trail."
  type        = string
}

variable "security_account_id" {
  description = "Security account whose SecurityAudit users may decrypt logs."
  type        = string
}
