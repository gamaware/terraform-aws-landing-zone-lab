# Copilot code review instructions

This repository is a Terraform landing zone lab with fictional data (client "Harbor Goods").

- Flag any account ID other than 111122223333, 444455556666, 777788889999, 123456789012 or 555555555555.
- Flag IAM, KMS or bucket policy statements that widen access without a condition, and SCP exemptions broader than
  `OrganizationAccountAccessRole`.
- Every provider block must set `allowed_account_ids`; member-account stacks assume a role.
- Module changes need a matching `terraform test` assertion; SCP changes need a matching case in
  `tests/policies/test_scps.py`.
- Checkov skips must sit next to the resource with a reason; flag new global skips.
- `make test-live` must keep its `CONFIRM_LIVE=yes` guard and teardown trap.
- Conventional commit PR titles. No suppressed lint rules.
