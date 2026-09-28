# 0005. Offline verification by default, a narrow live test

## Status

Accepted

## Context

Most of a landing zone cannot be tested cheaply against a real account. Creating an AWS Organizations member account is
quick, but closing one starts a 90-day suspension period, and the email address stays tied to it. Organization-level
changes (SCPs, delegated administrators, the organization trail) affect every account at once. A reviewer of this lab
should be able to check the work without an AWS account.

## Decision

- `make verify` is the only default check, locally and in CI. It runs `terraform fmt`, `validate` on every root and
  example, tflint, `terraform test` with a mocked AWS provider in every module, SCP policy tests in Python, a backend
  key test, Checkov and a guard that only AWS documentation example account IDs appear in the repository. It needs no
  credentials and makes no AWS API calls.
- `make test-live` exists but never runs by default: it refuses to start unless `CONFIRM_LIVE=yes` is set. Its scope is
  limited to resources that can be created and fully removed in one run in a single sandbox account: the log archive
  bucket and key, a VPC without NAT, the pipeline role and one budget. Organizations, accounts, SCPs, Identity Center
  and the organization trail are excluded.
- The live test tags everything `purpose=portfolio-test`, destroys in an exit trap, and fails if anything tagged remains
  (KMS keys in `PendingDeletion` count as removed).

## Consequences

- Mock tests prove what the code decides (targets, conditions, validations), not that AWS accepts it. Service-side
  behavior, such as SCP evaluation order or GuardDuty enrollment, is covered by the policy evaluator only as far as its
  documented grammar, and by the live test only for non-organization resources.
- The first real deployment still has to follow `docs/runbook.md` with a human reviewing each plan.

## Compliance

- The `verify` job in `.github/workflows/ci.yml` runs `make verify` and has no AWS credentials or `id-token` permission.
- `scripts/test-live.sh` exits with status 2 unless `CONFIRM_LIVE=yes`.

## Notes

- Closing a member account:
  <https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html>
- Live tests run private-only. The live root builds its VPC with `nat_gateway_mode = "none"`: no internet gateway,
  public subnet, NAT gateway or Elastic IP, and a default security group with no rules. The
  `tests/live/tests/private_only.tftest.hcl` run fails offline if that changes. Before applying,
  `scripts/test-live.sh` saves the plan and `scripts/check_private_plan.py` refuses it if any resource would be
  internet-facing (internet or public NAT gateway, Elastic IP, default route to the internet, public load balancer,
  `0.0.0.0/0` or `::/0` ingress, public IP, public database, open bucket or public endpoint) or uses Route 53. The
  checker is a byte-identical copy shared across the portfolio repositories.
