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

variable "log_bucket_name" {
  description = "Central log bucket, from the log-archive stack output."
  type        = string
}

variable "log_kms_key_arn" {
  description = "Log archive KMS key, from the log-archive stack output."
  type        = string
}

variable "state_bucket_name" {
  description = "Terraform state bucket, from the bootstrap output. Its object reads and writes are recorded as S3 data events."
  type        = string
}
