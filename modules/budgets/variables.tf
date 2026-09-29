variable "budgets" {
  description = "Monthly USD budgets keyed by name. Leave account_id null for an organization-wide budget; set forecast_alert = false to skip the forecast notification."
  type = map(object({
    limit_usd          = number
    account_id         = optional(string)
    actual_thresholds  = optional(list(number), [80, 100])
    forecast_alert     = optional(bool, true)
    forecast_threshold = optional(number, 100)
  }))

  validation {
    condition     = alltrue([for b in values(var.budgets) : b.limit_usd > 0])
    error_message = "Every budget needs a positive limit_usd."
  }

  validation {
    condition     = alltrue([for b in values(var.budgets) : b.account_id == null || can(regex("^[0-9]{12}$", b.account_id))])
    error_message = "account_id must be null or a 12-digit AWS account ID."
  }

  validation {
    condition     = alltrue([for b in values(var.budgets) : alltrue([for t in b.actual_thresholds : t > 0 && t <= 200])])
    error_message = "Thresholds are percentages between 1 and 200."
  }

  validation {
    condition     = alltrue([for b in values(var.budgets) : b.forecast_threshold > 0 && b.forecast_threshold <= 200])
    error_message = "forecast_threshold is a percentage between 1 and 200."
  }
}

variable "subscriber_emails" {
  description = "Addresses notified when a threshold is crossed. AWS Budgets allows up to 10 per notification."
  type        = list(string)

  validation {
    condition     = length(var.subscriber_emails) > 0 && length(var.subscriber_emails) <= 10
    error_message = "Provide between 1 and 10 subscriber email addresses."
  }
}

variable "tags" {
  description = "Tags applied to each budget."
  type        = map(string)
  default     = {}
}
