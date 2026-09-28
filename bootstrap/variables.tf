variable "region" {
  description = "Home region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "management_account_id" {
  description = "Management account ID. The provider refuses to run against any other account."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the Terraform state bucket."
  type        = string
}

variable "tags" {
  description = "Default tags for every resource."
  type        = map(string)
  default = {
    Project   = "landing-zone"
    ManagedBy = "terraform"
    Stack     = "bootstrap"
  }
}
