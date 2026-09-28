variable "name" {
  description = "Name prefix for the VPC and its resources."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. Must be a /16 so each AZ gets a /20 public and a /20 private subnet."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && endswith(var.cidr_block, "/16")
    error_message = "cidr_block must be a valid IPv4 /16, for example 10.20.0.0/16."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across, two or three."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3
    error_message = "Use two or three availability zones."
  }
}

variable "nat_gateway_mode" {
  description = "none (private only, no internet), single (one NAT gateway, lower cost) or per_az (one per AZ, no cross-AZ dependency)."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be none, single or per_az."
  }
}

variable "flow_log_retention_days" {
  description = "Retention of VPC flow logs in CloudWatch Logs."
  type        = number
  default     = 365
}

variable "share_with_principals" {
  description = "RAM principals (OU ARNs or account IDs inside the organization) that receive the private subnets."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
