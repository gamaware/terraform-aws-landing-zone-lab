variable "profile" {
  description = "AWS CLI profile for the sandbox account."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Region for the live test."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "Sandbox account ID. The script passes LIVE_ACCOUNT_ID only after sts get-caller-identity returns the same value."
  type        = string
}

variable "suffix" {
  description = "Random suffix so parallel or leftover runs never collide."
  type        = string
}

variable "oidc_provider_arn" {
  description = "Existing GitHub OIDC provider in the sandbox account, or null to create one."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Address for the test budget alert."
  type        = string
  default     = "finops@example.com"
}
