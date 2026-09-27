# 0004. One home region, a second approved region

## Status

Accepted

## Context

Harbor Goods serves customers in North America and has no data residency requirement. Every extra region adds Config
recorders, GuardDuty detectors and Security Hub findings to operate, and cross-region replication doubles storage for
logs and state.

## Decision

- `us-east-1` is the home region for every stack, state and log bucket. `us-west-2` is approved in the region SCP for
  disaster recovery, but nothing is deployed there yet.
- Global resource types are recorded by AWS Config only in the home region.
- S3 cross-region replication for the log archive and state buckets is not enabled; Checkov's replication check is
  skipped next to the bucket resource with this ADR as the reason.

## Consequences

- A regional outage in `us-east-1` stops log delivery and Terraform runs until it recovers. Logs already written are
  durable in S3.
- Adding `us-west-2` later means a `environments/<account>/us-west-2/` tree with the same stacks and
  `record_global_resources = false`.

## Compliance

- `modules/config-recorder/tests/config_recorder.tftest.hcl` asserts that global resources are recorded only when
  `record_global_resources` is true.
- `tests/policies/test_scps.py` asserts the approved region list.

## Notes

- Example SCPs, including the region deny pattern:
  <https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples_general.html>
