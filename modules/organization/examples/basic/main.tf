# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region              = var.region
  allowed_account_ids = ["111122223333"]
}

module "organization" {
  source = "../.."

  accounts = {
    log-archive = { name = "log-archive", email = "aws-log-archive@example.com", ou = "Security" }
    security    = { name = "security", email = "aws-security@example.com", ou = "Security" }
    workloads   = { name = "workloads", email = "aws-workloads@example.com", ou = "Workloads" }
  }

  service_control_policies = {
    deny-leave-organization = {
      file        = "${path.module}/../../../../policies/scp/deny-leave-organization.json"
      description = "Member accounts cannot leave the organization."
      targets     = ["Root"]
    }
  }
}
