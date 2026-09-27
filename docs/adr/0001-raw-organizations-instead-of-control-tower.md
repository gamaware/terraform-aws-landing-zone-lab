# 0001. Raw AWS Organizations instead of AWS Control Tower

## Status

Accepted

## Context

Harbor Goods needs a multi-account foundation for a new product: separate accounts for logs, security, shared
networking and workloads, single sign-on, guardrails and budgets. AWS offers a managed way to build this, AWS Control
Tower, which sets up a landing zone with an Account Factory, a log archive and audit account, preventive and detective
controls, and drift detection.

Control Tower is the right choice for many organizations, but it has trade-offs for this engagement:

- It owns parts of the foundation (the log archive and audit accounts, its CloudTrail and Config setup, its guardrail
  SCPs). Changing them outside Control Tower counts as drift and has to be repaired through the console or a landing
  zone update.
- Its control library and landing zone versions move on AWS's schedule; upgrades are an operational task of their own.
- The Terraform path for account vending is Account Factory for Terraform (AFT), which adds its own pipeline, repos and
  accounts. That is a lot of moving parts for four member accounts.
- The client's team has to learn Control Tower's model on top of Organizations, SCPs and Identity Center.
- A lab has to be reviewable offline. Control Tower's landing zone cannot be exercised with mocked providers in a
  meaningful way; plain Organizations resources can.

## Decision

Build the foundation directly on AWS Organizations with Terraform: OUs, accounts, SCPs, an organization trail, delegated
administrators for GuardDuty, Security Hub and AWS Config, IAM Identity Center permission sets, a shared VPC, budgets
and a pipeline role. Every piece is code the client owns and can read in one repository.

Control Tower remains the recommended alternative when the client wants AWS to manage the landing zone lifecycle, needs
its control library for a compliance framework, or expects to vend dozens of accounts. The account layout here (Security
OU with log-archive and security accounts, separate Infrastructure and Workloads OUs) matches Control Tower's, so
enrolling these accounts later is a migration, not a rebuild.

## Consequences

- The client can change any guardrail with a pull request and review it in a plan, without console drift repair.
- Detective controls come from Security Hub standards and AWS Config instead of Control Tower's control library; there
  is no Account Factory UI, so new accounts are added to `environments/management/us-east-1/organization/terraform.tfvars`.
- The client carries the upgrade work that Control Tower would do: new GuardDuty protection plans, new Security Hub
  standards, SCP updates for new global services.
- Moving to Control Tower later means enrolling the existing OUs and accounts and removing the resources that Control
  Tower then manages (organization trail, Config recorders), in that order.

## Compliance

- `modules/organization/tests/organization.tftest.hcl` asserts the OU layout, SCP targets and delegated administrators.
- `tests/policies/test_scps.py` asserts what each SCP denies.
- A review of `environments/` finds no `aws_controltower_*` resources; adding any would supersede this ADR.

## Notes

- AWS Control Tower overview: <https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html>
- Organizing your AWS environment using multiple accounts (AWS whitepaper):
  <https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html>
