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
}

variable "subscriber_emails" {
  description = "Addresses that receive budget alerts."
  type        = list(string)
}
