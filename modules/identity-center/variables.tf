variable "permission_sets" {
  description = "Permission sets keyed by name. session_duration is ISO 8601, from PT1H to PT12H."
  type = map(object({
    description         = string
    session_duration    = optional(string, "PT1H")
    managed_policy_arns = optional(list(string), [])
    inline_policy       = optional(string)
  }))

  validation {
    condition     = alltrue([for ps in values(var.permission_sets) : can(regex("^PT([1-9]|1[0-2])H$", ps.session_duration))])
    error_message = "session_duration must be a whole number of hours between PT1H and PT12H."
  }

  validation {
    condition = alltrue([
      for ps in values(var.permission_sets) :
      !contains(ps.managed_policy_arns, "arn:aws:iam::aws:policy/AdministratorAccess") || ps.session_duration == "PT1H"
    ])
    error_message = "A permission set with AdministratorAccess must keep a one-hour session (PT1H)."
  }
}

variable "assignments" {
  description = "Group-to-account assignments. group is the Identity Center group display name."
  type = list(object({
    group          = string
    permission_set = string
    account_id     = string
  }))
  default = []

  validation {
    condition     = alltrue([for a in var.assignments : can(regex("^[0-9]{12}$", a.account_id))])
    error_message = "Every assignment account_id must be a 12-digit AWS account ID."
  }

  validation {
    condition     = alltrue([for a in var.assignments : contains(keys(var.permission_sets), a.permission_set)])
    error_message = "Every assignment must use a permission set defined in permission_sets."
  }
}

variable "tags" {
  description = "Tags applied to permission sets."
  type        = map(string)
  default     = {}
}
