variable "role_name" {
  description = "Name of the deploy role. The boundary policy is named <role_name>-boundary."
  type        = string
  default     = "github-actions-deploy"
}

variable "github_subjects" {
  description = "Exact OIDC subjects allowed to assume the role, for example repo:harbor-goods/storefront:environment:production."
  type        = list(string)

  validation {
    condition     = length(var.github_subjects) > 0
    error_message = "Provide at least one subject."
  }

  validation {
    condition     = alltrue([for s in var.github_subjects : !strcontains(s, "*") && !strcontains(s, "?")])
    error_message = "Subjects must be exact: wildcards would let other branches, tags or forks assume the role."
  }

  validation {
    condition     = alltrue([for s in var.github_subjects : can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:(environment:[A-Za-z0-9_.-]+|ref:refs/heads/[A-Za-z0-9_./-]+|ref:refs/tags/[A-Za-z0-9_./-]+)$", s))])
    error_message = "Subjects must be repo:<owner>/<repo>:environment:<name> or a ref:refs/heads/ or ref:refs/tags/ subject."
  }
}

variable "oidc_provider_arn" {
  description = "Existing GitHub OIDC provider in the account. Null creates one; an account can hold only one per URL."
  type        = string
  default     = null
}

variable "allowed_actions" {
  description = "Actions the permissions boundary allows. The deploy policy grants a subset; the boundary is the ceiling."
  type        = list(string)
  default = [
    "application-autoscaling:*",
    "cloudwatch:*",
    "ecr:*",
    "ecs:*",
    "elasticloadbalancing:*",
    "iam:GetRole",
    "lambda:*",
    "logs:*",
    "s3:*",
    "ssm:GetParameter*",
  ]

  validation {
    condition     = !contains(var.allowed_actions, "*") && !contains(var.allowed_actions, "iam:*")
    error_message = "The boundary must not allow * or iam:*."
  }

  validation {
    condition     = !contains([for a in var.allowed_actions : lower(a)], "iam:passrole")
    error_message = "Grant iam:PassRole through passable_role_arns, which scopes it to named roles and services."
  }
}

variable "passable_role_arns" {
  description = "Role ARNs (or ARN patterns) the pipeline may pass, for example task execution roles of the workload."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.passable_role_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", arn)) && !endswith(arn, ":role/*")])
    error_message = "passable_role_arns must name roles in a specific account; role/* is not allowed."
  }
}

variable "pass_role_services" {
  description = "Services the pipeline may pass those roles to."
  type        = list(string)
  default     = ["ecs-tasks.amazonaws.com"]
}

variable "deploy_policy_json" {
  description = "Inline policy with the permissions the pipeline actually needs. Null leaves the role with no permissions."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session length in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 3600
    error_message = "Keep pipeline sessions between 15 minutes and one hour."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
