variable "region" {
  description = "Region this stack deploys to."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "Account this stack deploys to. The provider refuses any other."
  type        = string
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

variable "member_account_ids" {
  description = "Member account IDs keyed by account key, from the organization stack output."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["log-archive", "security", "shared", "workloads"] : contains(keys(var.member_account_ids), k)])
    error_message = "member_account_ids needs log-archive, security, shared and workloads."
  }
}
