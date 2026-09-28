locals {
  stack = "identity-center"
}

module "identity_center" {
  source = "../../../../modules/identity-center"

  permission_sets = {
    PlatformAdmin = {
      description         = "Full access for the platform team, one-hour sessions."
      session_duration    = "PT1H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    Developer = {
      description         = "Build and operate workloads; no IAM user or organization changes."
      session_duration    = "PT8H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    ReadOnly = {
      description         = "Read-only access for reviews and support."
      session_duration    = "PT8H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    SecurityAudit = {
      description         = "Security review across every account."
      session_duration    = "PT4H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/SecurityAudit", "arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  assignments = concat(
    [for id in values(var.member_account_ids) : { group = "platform-admins", permission_set = "PlatformAdmin", account_id = id }],
    [for id in values(var.member_account_ids) : { group = "security-auditors", permission_set = "SecurityAudit", account_id = id }],
    [{ group = "developers", permission_set = "Developer", account_id = var.member_account_ids["workloads"] }],
    [{ group = "developers", permission_set = "ReadOnly", account_id = var.member_account_ids["shared"] }],
  )
}
