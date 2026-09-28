# AWS Organizations: the organization, one level of OUs, member accounts,
# service control policies and the delegated administrators that move security
# tooling out of the management account.

resource "aws_organizations_organization" "this" {
  feature_set                   = "ALL"
  aws_service_access_principals = sort(var.service_access_principals)
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
}

locals {
  root_id = aws_organizations_organization.this.roots[0].id

  # Each SCP can target the root ("Root") or any OU by name. Flatten to one
  # attachment per policy and target so keys stay stable in state.
  policy_attachments = merge([
    for policy_name, policy in var.service_control_policies : {
      for target in policy.targets : "${policy_name}/${target}" => {
        policy = policy_name
        target = target
      }
    }
  ]...)

  target_ids = merge(
    { Root = local.root_id },
    { for name, ou in aws_organizations_organizational_unit.this : name => ou.id },
  )

  delegated_admin_account_id = aws_organizations_account.this[var.security_account_key].id
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = toset(var.organizational_units)

  name      = each.value
  parent_id = local.root_id
  tags      = var.tags
}

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  parent_id                  = aws_organizations_organizational_unit.this[each.value.ou].id
  role_name                  = var.cross_account_role_name
  iam_user_access_to_billing = "DENY"
  close_on_deletion          = false
  tags                       = merge(var.tags, { AccountKey = each.key })

  # Closing an account starts a 90-day suspension and frees the email only
  # after that. Removing an account from code must be a deliberate, reviewed
  # change, so Terraform refuses to destroy one.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name, iam_user_access_to_billing]
  }
}

resource "aws_organizations_policy" "scp" {
  for_each = var.service_control_policies

  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = file(each.value.file)
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "scp" {
  for_each = local.policy_attachments

  policy_id = aws_organizations_policy.scp[each.value.policy].id
  target_id = local.target_ids[each.value.target]

  lifecycle {
    precondition {
      condition     = contains(keys(local.target_ids), each.value.target)
      error_message = "SCP ${each.value.policy} targets ${each.value.target}, which is neither Root nor a declared OU."
    }
  }
}

resource "aws_ram_sharing_with_organization" "this" {
  count = var.enable_ram_sharing ? 1 : 0

  depends_on = [aws_organizations_organization.this]
}

# Delegated administrators. The security account runs GuardDuty, Security Hub
# and the AWS Config aggregator for the whole organization. Both services must
# be enabled in the management account before it can delegate them, and the
# management account is then monitored like any member.
resource "aws_guardduty_detector" "management" {
  #checkov:skip=CKV2_AWS_3:The organization configuration lives in the security account, the delegated administrator (modules/security-services).
  enable = true
  tags   = var.tags
}

resource "aws_securityhub_account" "management" {
  enable_default_standards = false
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = local.delegated_admin_account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = local.delegated_admin_account_id

  depends_on = [aws_organizations_organization.this, aws_guardduty_detector.management]
}

resource "aws_securityhub_organization_admin_account" "this" {
  admin_account_id = local.delegated_admin_account_id

  depends_on = [aws_organizations_organization.this, aws_securityhub_account.management]
}
