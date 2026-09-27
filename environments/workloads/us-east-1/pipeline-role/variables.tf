variable "region" {
  description = "Region this stack deploys to."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "Account this stack deploys to. The provider refuses any other."
  type        = string
}

variable "deploy_role_name" {
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

variable "github_subjects" {
  description = "Exact GitHub OIDC subjects allowed to deploy into this account."
  type        = list(string)
}
