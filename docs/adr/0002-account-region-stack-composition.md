# 0002. One state per account, region and stack

## Status

Accepted

## Context

A landing zone spans five accounts. Putting everything in one Terraform root would make every plan touch the
organization, every apply need management-account credentials for all resources, and one failed apply block unrelated
changes. Splitting by environment branches or copying code per account would let accounts drift apart.

## Decision

- Reusable logic lives in `modules/<name>/`, each with examples and mocked tests.
- Deployable roots live in `environments/<account>/<region>/<stack>/`. Each is a thin root with its own state key
  (`<account>/<region>/<stack>/terraform.tfstate`) in one S3 bucket created by `bootstrap/`, with S3 native locking
  (`use_lockfile`), so there is no DynamoDB lock table.
- Stacks are split by blast radius and rate of change: the organization stack changes rarely and affects everyone; the
  network or pipeline-role stacks change more often and affect one account.
- Member-account stacks assume `OrganizationAccountAccessRole` from management-account credentials, and every provider
  sets `allowed_account_ids`, so a wrong role ARN fails before any change.
- Stacks pass values to each other through `terraform.tfvars` (for example the log bucket name and KMS key ARN), not
  `terraform_remote_state`. The dependency is visible in review and a stack can be planned without reading another
  stack's state.
- Environments live on the same branch as folders, never as branches.

## Consequences

- A change to the pipeline role cannot touch the organization, and a broken network plan does not block an SCP fix.
- Cross-stack values are copied by hand after the producing stack is applied. The deployment order is documented in
  `docs/runbook.md`; a production engagement would move these values to SSM parameters or a small wrapper.
- Modules are referenced by relative path, so all stacks use the version in the same commit. A multi-repo setup would
  pin module versions by Git tag instead.

## Compliance

- `make validate` and the CI `terraform` job validate every root under `environments/`.
- `make lint` runs tflint with `terraform_standard_module_structure` on every root and module.
- `tests/structure/test_backend_keys.py` (`make structure-test`) asserts that each root's backend key matches its
  path and that no two roots share a key.

## Notes

- S3 backend and native state locking (`use_lockfile`):
  <https://developer.hashicorp.com/terraform/language/backend/s3>
- ADR 0005 describes how these roots are verified without an AWS account.
