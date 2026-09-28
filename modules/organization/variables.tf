variable "organizational_units" {
  description = "OUs created directly under the root."
  type        = list(string)
  default     = ["Security", "Infrastructure", "Workloads"]

  validation {
    condition     = length(var.organizational_units) == length(distinct(var.organizational_units))
    error_message = "OU names must be unique."
  }
}

variable "accounts" {
  description = "Member accounts keyed by a short stable key. ou must be one of organizational_units."
  type = map(object({
    name  = string
    email = string
    ou    = string
  }))

  validation {
    condition     = alltrue([for a in values(var.accounts) : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", a.email))])
    error_message = "Every account needs a valid, unique root email address."
  }

  validation {
    condition     = length(values(var.accounts)) == length(distinct([for a in values(var.accounts) : lower(a.email)]))
    error_message = "Account root email addresses must be unique across the organization."
  }

  validation {
    condition     = alltrue([for a in values(var.accounts) : contains(var.organizational_units, a.ou)])
    error_message = "Every account must be placed in one of organizational_units."
  }
}

variable "security_account_key" {
  description = "Key in accounts for the account that becomes delegated administrator for GuardDuty, Security Hub and AWS Config."
  type        = string
  default     = "security"

  validation {
    condition     = contains(keys(var.accounts), var.security_account_key)
    error_message = "security_account_key must be a key of accounts."
  }
}

variable "cross_account_role_name" {
  description = "Role Organizations creates in each new account, trusted by the management account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "service_access_principals" {
  description = "AWS services given trusted access to the organization."
  type        = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "guardduty.amazonaws.com",
    "malware-protection.guardduty.amazonaws.com",
    "ram.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]
}

variable "service_control_policies" {
  description = "SCPs keyed by name: the JSON file, a description and the targets (Root or OU names)."
  type = map(object({
    file        = string
    description = string
    targets     = list(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.service_control_policies) : length(p.targets) > 0])
    error_message = "Every SCP needs at least one target."
  }
}

variable "enable_ram_sharing" {
  description = "Let AWS RAM share resources, such as the shared VPC subnets, with the whole organization."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to OUs, accounts and policies."
  type        = map(string)
  default     = {}
}
