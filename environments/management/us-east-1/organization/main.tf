locals {
  stack      = "organization"
  policy_dir = "${path.root}/../../../../policies/scp"
}

module "organization" {
  source = "../../../../modules/organization"

  organizational_units = ["Security", "Infrastructure", "Workloads"]
  accounts             = var.accounts
  security_account_key = "security"

  service_control_policies = {
    deny-leave-organization = {
      file        = "${local.policy_dir}/deny-leave-organization.json"
      description = "Member accounts cannot leave the organization."
      targets     = ["Root"]
    }
    deny-root-user = {
      file        = "${local.policy_dir}/deny-root-user.json"
      description = "The root user of member accounts cannot act."
      targets     = ["Root"]
    }
    protect-security-baseline = {
      file        = "${local.policy_dir}/protect-security-baseline.json"
      description = "Only the landing zone management access role can change CloudTrail, Config, GuardDuty or Security Hub."
      targets     = ["Root"]
    }
    restrict-regions = {
      file        = "${local.policy_dir}/restrict-regions.json"
      description = "Regional services only in us-east-1 and us-west-2."
      targets     = ["Infrastructure", "Workloads"]
    }
  }
}
