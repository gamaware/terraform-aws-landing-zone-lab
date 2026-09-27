# 0006. Security tooling runs from a delegated administrator account

## Status

Accepted

## Context

GuardDuty, Security Hub and AWS Config aggregation can be run from the management account, but that account also holds
billing, Organizations and Identity Center. Every person who needs to read security findings would then need access to
the most powerful account in the organization.

## Decision

- The organization stack registers the security account as delegated administrator for GuardDuty, Security Hub and AWS
  Config (`config.amazonaws.com`).
- The security-services stack, applied in the security account, enables GuardDuty with auto-enrolment of every member
  and the S3 Protection and EBS Malware Protection plans, Security Hub with auto-enable and the AWS Foundational
  Security Best Practices and CIS standards, and an organization-wide Config aggregator.
- Logs stay in the log-archive account; the security account's `SecurityAudit` permission set users can decrypt them,
  scoped by `aws:PrincipalOrgID` and a role ARN pattern in the log key policy.
- Identity Center stays in the management account in this lab. Delegating it is a production adaptation.

## Consequences

- Security reviewers work in the security account with the `SecurityAudit` permission set and never need
  management-account access.
- The delegation must be applied before the security-services stack; the runbook orders them.

## Compliance

- `modules/organization/tests/organization.tftest.hcl` asserts that all three delegations point at the security account.
- `modules/security-services/tests/security_services.tftest.hcl` asserts auto-enrolment and the standards.
