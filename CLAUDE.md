# CLAUDE.md

Project instructions for Claude Code in `terraform-aws-landing-zone-lab`. Global rules in `~/.claude/CLAUDE.md` apply.

## Overview

A Terraform landing zone lab for a fictional client, Harbor Goods: AWS Organizations with OUs and SCPs, an organization
CloudTrail into a log-archive account, GuardDuty, Security Hub and AWS Config delegated to a security account, IAM
Identity Center permission sets, a shared VPC, budgets and a GitHub OIDC pipeline role. Offline-verifiable; nothing
here has been deployed to a real organization.

## Structure

- `modules/<name>/`: reusable modules, each with `examples/basic/` and `tests/*.tftest.hcl` (mocked provider).
- `environments/<account>/<region>/<stack>/`: thin deployable roots, one state each.
- `bootstrap/`: state bucket, local state until migrated.
- `policies/scp/`: SCP JSON, attached by `environments/management/us-east-1/organization`.
- `tests/policies/`: SCP structure and outcome tests (stdlib `unittest`, no dependencies).
- `tests/live/` and `scripts/test-live.sh`: opt-in live test for non-organization modules only.
- `docs/adr/`, `docs/runbook.md`, `docs/diagrams/`.

## Rules

- Example account IDs only: 111122223333 (management), 444455556666 (log-archive), 777788889999 (security),
  123456789012 (shared), 555555555555 (workloads). `make example-ids` enforces this.
- Every provider block sets `allowed_account_ids`. Member stacks assume `OrganizationAccountAccessRole`.
- Each root has a unique backend key `<account>/<region>/<stack>/terraform.tfstate`.
- Module behaviour changes need a `terraform test` assertion; SCP changes need a case in `tests/policies/test_scps.py`.
- Checkov skips sit next to the resource with a reason. No global skips in `.checkov.yaml`.
- Never run `make test-live` unless the user asks. It needs `CONFIRM_LIVE=yes`, uses the `dev` profile, and must be
  preceded by `aws sts get-caller-identity --profile dev`.
- Lock files: committed for `bootstrap/` and `environments/`, generated with
  `terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64`.

## Verification

`make verify` runs fmt, validate, tflint, `terraform test`, SCP tests, Checkov and the example-ID guard. It must pass
before every commit, together with `pre-commit run --all-files`.

## Git workflow

Feature branches only, conventional commits, squash merge. No AI attribution anywhere.

## CI

`.github/workflows/ci.yml` calls the shared reusable workflows in `gamaware/.github` (lint-docs, lint-actions, secrets,
security, terraform) and runs `make verify` in its own job. PR jobs never get AWS credentials or `id-token`.

## Code review

CodeRabbit (`.coderabbit.yaml`) and GitHub Copilot (`.github/copilot-instructions.md`) review every PR.
