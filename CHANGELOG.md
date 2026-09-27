# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the modules follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- AWS Organizations foundation: Security, Infrastructure and Workloads OUs, four member accounts, and SCPs that deny
  leaving the organization, root user actions, regions outside `us-east-1` and `us-west-2`, and tampering with
  CloudTrail, AWS Config, GuardDuty and Security Hub.
- Organization CloudTrail delivered to a KMS-encrypted log-archive bucket, with a CloudWatch Logs copy.
- GuardDuty, Security Hub and AWS Config aggregation delegated to the security account; a Config recorder baseline in
  every member account.
- IAM Identity Center permission sets and group assignments.
- Shared VPC in the shared account with private subnets shared to the Workloads OU through AWS RAM.
- Monthly budgets per account and for the organization.
- GitHub OIDC pipeline role for the workloads account, with exact subjects and a permissions boundary.
- Offline verification: `terraform test` with a mocked provider in every module, SCP policy tests, tflint, Checkov and
  an example-account-ID guard, all behind `make verify`.
- Opt-in `make test-live` for non-organization modules, guarded by `CONFIRM_LIVE=yes`.
- Six ADRs, a deployment runbook and architecture diagrams.

### Security

- Every action and shared `gamaware/.github` reusable workflow is pinned to a full commit SHA; `zizmor.yml` enforces
  hash pins for all of them.
