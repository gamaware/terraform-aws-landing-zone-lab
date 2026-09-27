# Deployment runbook

Follow this sequence for the first landing zone deployment for Harbor Goods, a fictional client. The repository contains
example values throughout. Before the first plan, substitute the client's account IDs, emails and bucket names.

This lab has not included execution of the runbook against a real organization. Use `make verify` for offline code
checks; `make test-live` covers only modules outside the organization scope, as described in
[ADR 0005](adr/0005-offline-verification-and-live-scope.md).

## Prerequisites

- A new AWS account designated as the management account, with root-user MFA enabled and no workloads.
- An administrator session in that account using a temporary IAM Identity Center user or role; root access keys
  are excluded.
- Terraform version 1.14.5 or newer within the 1.x series, AWS CLI v2, and a reviewed commit of this repository.
- Four available email addresses for member accounts; plus-addressing through a single mailbox is sufficient.

Before starting each stage, run `aws sts get-caller-identity` and verify that the returned account ID is correct for it.

## Order

| Step | Directory | Account | Needs from earlier steps |
| --- | --- | --- | --- |
| 1 | `bootstrap/` | management | nothing |
| 2 | `environments/management/us-east-1/organization` | management | state bucket |
| 3 | `environments/log-archive/us-east-1/log-archive` | log-archive | organization ID, account IDs |
| 4 | `environments/management/us-east-1/org-trail` | management | log bucket name, log KMS key ARN |
| 5 | `environments/security/us-east-1/security-services` | security | delegations from step 2 |
| 6 | `environments/<account>/us-east-1/baseline` (four stacks) | each member | log bucket name, log KMS key ARN |
| 7 | `environments/management/us-east-1/identity-center` | management | account IDs, Identity Center enabled |
| 8 | `environments/shared/us-east-1/network` | shared | Workloads OU ARN |
| 9 | `environments/workloads/us-east-1/pipeline-role` | workloads | the client repository's OIDC subjects |
| 10 | `environments/management/us-east-1/budgets` | management | account IDs, alert addresses |

## Stages

### 1. Bootstrap state

```bash
cd bootstrap
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Checkpoint: confirm that the plan creates exactly two buckets, including their settings and policies, one KMS key and
one alias. Once the apply finishes, enable the commented-out backend block in `bootstrap/versions.tf`, execute
`terraform init -migrate-state -backend-config=../environments/backend.hcl`, then remove the local state file.

### 2. Organization

```bash
cd environments/management/us-east-1/organization
terraform init -backend-config=../../../backend.hcl
terraform plan -out=tfplan
```

Checkpoint: verify that the plan includes three OUs, four accounts and four SCPs, with attachments matching the
`policy_attachments` output. It must also enable GuardDuty and Security Hub in the management account and register
three delegated administrators. Allow a few minutes for each account's creation.

Rollback trigger: the plan proposes replacing or destroying any account. Halt the deployment and investigate.
The accounts have `prevent_destroy`; closing an account begins a 90-day suspension.

Populate the later stacks' `terraform.tfvars` with `organization_id`, `account_ids` and the Workloads OU ARN
from the outputs.

### 3-4. Log archive, then the organization trail

Deploy the log-archive stack before applying org-trail, passing the bucket name and key ARN from the
log-archive outputs.

Checkpoint: verify that objects arrive in the log bucket at `AWSLogs/<organization-id>/` within 15 minutes.
Confirm that `aws cloudtrail get-trail-status --name organization-trail` returns `IsLogging: true`.

### 5. Security services

Run the apply in the security account. When step 2's delegation has already enabled Security Hub there, the initial
apply reports an existing subscription. In that case, import the account using
`terraform import module.security_services.aws_securityhub_account.this 777788889999`, then rerun the plan.

Checkpoint: confirm that every member account appears as enabled in both GuardDuty and Security Hub.
After step 6 finishes, verify that the Config aggregator called `organization` includes all accounts.

### 6. Account baselines

Deploy all four `baseline` stacks. AWS permits one Config recorder in each region; for an account with an existing
recorder, import it into `module.config_recorder.aws_config_configuration_recorder.this` before running the plan.

Checkpoint: check each account with `aws configservice describe-configuration-recorder-status` and confirm
`recording: true`.

### 7. Identity Center

Start by enabling IAM Identity Center through the management account console; Terraform cannot enable it.
Create `platform-admins`, `security-auditors` and `developers` as groups before applying the stack.

Checkpoint: verify that `platform-admins` members can access every account through `PlatformAdmin` and that all
other users are denied that access. After this check, remove the temporary administrator used in the preceding stages.

### 8-10. Network, pipeline role, budgets

Deploy these stacks in the listed sequence. The network stack's primary fixed monthly expense is a single NAT gateway.
Set `nat_gateway_mode = "none"` until outbound internet access becomes necessary for a workload.

Checkpoint for the pipeline role: verify that a workflow running in the client repository's `production` environment
can assume the role. Confirm that STS rejects runs from any other branch or environment.

## Acceptance criteria

The deployment is accepted when it meets the seven criteria in the
[README](../README.md#scenario-and-acceptance-criteria). Criteria 4 and 7 need the real organization; check them
after the security-services and budgets stacks are applied.
