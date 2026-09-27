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

variable "workloads_ou_arn" {
  description = "Workloads OU ARN, from the organization stack output. Its accounts receive the private subnets."
  type        = string
}

variable "nat_gateway_mode" {
  description = "none, single or per_az. single keeps the lab's fixed cost to one NAT gateway."
  type        = string
  default     = "single"
}
