# 0003. Deny-list SCPs with one management access role exemption

## Status

Accepted

## Context

Service control policies set the maximum permissions for every principal in member accounts, including account
administrators. The foundation needs four guardrails: no account leaves the organization, no regional services outside
approved regions, nobody disables the audit and detection baseline, and the root user of member accounts does nothing.

Two SCP strategies exist: allow-lists (remove `FullAWSAccess`, allow only listed services) and deny-lists (keep
`FullAWSAccess`, deny specific actions). Allow-lists break new services silently and are hard to reason about for a
small team.

The baseline itself (AWS Config recorders in member accounts, the management access role) is managed by Terraform
through `OrganizationAccountAccessRole`, called the management access role here, so a guardrail that denies everyone
would block its own maintenance.

## Decision

- Keep `FullAWSAccess` and attach Deny-only SCPs from `policies/scp/`:
  - `deny-leave-organization` and `deny-root-user` at the root.
  - `protect-security-baseline` at the root: CloudTrail, AWS Config, GuardDuty and Security Hub changes, plus changes to
    the management access role itself, are denied to everyone except `OrganizationAccountAccessRole`.
  - `restrict-regions` on the Infrastructure and Workloads OUs: regional actions outside `us-east-1` and `us-west-2` are
    denied, global services are exempt through `NotAction`, and the management access role is exempt for break-glass
    work.
- The Security OU has no region restriction: its accounts run organization-wide detection and read findings from every
  region.
- The exemption names exactly `arn:aws:iam::*:role/OrganizationAccountAccessRole`, never a wildcard role path.

## Consequences

- Anyone who can assume `OrganizationAccountAccessRole` can change the baseline. That role is trusted only by the
  management account, which is why management-account access is limited to the platform team (see ADR 0006).
- SCPs never apply to the management account; the organization trail and Identity Center live there and are protected
  by limiting who can sign in to it.
- Adding a region is a one-line change in `restrict-regions.json` plus the matching test constant.

## Compliance

- `tests/policies/test_scps.py` evaluates realistic requests against each policy: region denials, global-service
  exemptions, tampering denials for developer and pipeline roles, the management access role exemption, and the exact
  exemption ARN. It also checks size limits, Deny-only statements and that every file is attached by the organization
  stack.
- `modules/organization/tests/organization.tftest.hcl` asserts the attachment targets.

## Notes

- Service control policies:
  <https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html>
- The management access role is `OrganizationAccountAccessRole`, which AWS Organizations creates in each member account.
  It is not the GitHub OIDC pipeline role in `modules/pipeline-role/`.
