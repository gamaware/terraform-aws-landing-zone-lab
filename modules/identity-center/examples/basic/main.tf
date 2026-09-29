# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region              = var.region
  allowed_account_ids = ["111122223333"]
}

module "identity_center" {
  source = "../.."

  permission_sets = {
    ReadOnly = {
      description         = "Read-only access."
      session_duration    = "PT4H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  assignments = [
    { group = "developers", permission_set = "ReadOnly", account_id = "555555555555" },
  ]
}
