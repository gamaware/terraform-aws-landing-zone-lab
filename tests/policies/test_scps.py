"""Offline tests for the service control policies in policies/scp/.

Two layers: structural checks every SCP must pass (valid JSON, size limit,
Deny-only, unique Sids), then outcome checks that feed realistic requests
through scp_eval and assert which ones each guardrail blocks.

Run: python3 -m unittest discover -s tests/policies -v
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

from scp_eval import Request, UnsupportedPolicy, denied_by, load

ROOT = Path(__file__).resolve().parents[2]
SCP_DIR = ROOT / "policies" / "scp"
ORG_STACK = ROOT / "environments" / "management" / "us-east-1" / "organization" / "main.tf"

# AWS counts SCP size without insignificant whitespace; the limit is 5,120.
SCP_MAX_CHARS = 5120
APPROVED_REGIONS = {"us-east-1", "us-west-2"}

MANAGEMENT_ACCESS_ROLE = "arn:aws:iam::555555555555:role/OrganizationAccountAccessRole"
DEVELOPER = "arn:aws:iam::555555555555:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_Developer_0123456789abcdef"
PIPELINE = "arn:aws:iam::555555555555:role/github-actions-deploy"
ROOT_USER = "arn:aws:iam::555555555555:root"


def policies() -> dict[str, dict]:
    return {path.stem: load(path) for path in sorted(SCP_DIR.glob("*.json"))}


class StructureTest(unittest.TestCase):
    """Rules every SCP file must follow."""

    def test_directory_has_policies(self):
        self.assertGreaterEqual(len(policies()), 4)

    def test_valid_json_and_version(self):
        for name, policy in policies().items():
            with self.subTest(policy=name):
                self.assertEqual(policy["Version"], "2012-10-17")
                self.assertIsInstance(policy["Statement"], list)
                self.assertTrue(policy["Statement"])

    def test_within_scp_size_limit(self):
        for name, policy in policies().items():
            with self.subTest(policy=name):
                size = len(json.dumps(policy, separators=(",", ":")))
                self.assertLessEqual(size, SCP_MAX_CHARS, f"{name} is {size} characters")

    def test_deny_only_with_unique_sids(self):
        # The org keeps FullAWSAccess attached, so these files only subtract.
        for name, policy in policies().items():
            with self.subTest(policy=name):
                sids = [s.get("Sid") for s in policy["Statement"]]
                self.assertTrue(all(sids), "every statement needs a Sid")
                self.assertEqual(len(sids), len(set(sids)), "Sids must be unique")
                for statement in policy["Statement"]:
                    self.assertEqual(statement["Effect"], "Deny")

    def test_no_account_specific_arns(self):
        # Policies attach across the organization, so ARNs use * for the account.
        for name in policies():
            text = (SCP_DIR / f"{name}.json").read_text(encoding="utf-8")
            with self.subTest(policy=name):
                self.assertIsNone(re.search(r"arn:aws:iam::\d{12}:", text))

    def test_every_policy_is_attached_by_the_organization_stack(self):
        stack = ORG_STACK.read_text(encoding="utf-8")
        for name in policies():
            with self.subTest(policy=name):
                self.assertIn(f"/{name}.json", stack)


class DenyLeaveOrganizationTest(unittest.TestCase):
    policy = load(SCP_DIR / "deny-leave-organization.json")

    def test_nobody_can_leave(self):
        for principal in (DEVELOPER, MANAGEMENT_ACCESS_ROLE, PIPELINE):
            with self.subTest(principal=principal):
                request = Request("organizations:LeaveOrganization", principal)
                self.assertEqual(denied_by(self.policy, request), ["DenyLeaveOrganization"])

    def test_other_organizations_reads_allowed(self):
        request = Request("organizations:DescribeOrganization", DEVELOPER)
        self.assertEqual(denied_by(self.policy, request), [])


class DenyRootUserTest(unittest.TestCase):
    policy = load(SCP_DIR / "deny-root-user.json")

    def test_root_user_is_denied_everything(self):
        for action in ("s3:ListAllMyBuckets", "iam:CreateAccessKey", "ec2:RunInstances"):
            with self.subTest(action=action):
                self.assertEqual(denied_by(self.policy, Request(action, ROOT_USER)), ["DenyRootUser"])

    def test_roles_are_not_affected(self):
        self.assertEqual(denied_by(self.policy, Request("ec2:RunInstances", DEVELOPER)), [])


class RestrictRegionsTest(unittest.TestCase):
    policy = load(SCP_DIR / "restrict-regions.json")

    def test_regional_service_outside_approved_regions_is_denied(self):
        for region in ("eu-west-1", "ap-southeast-2", "sa-east-1"):
            with self.subTest(region=region):
                request = Request("ec2:RunInstances", DEVELOPER, region=region)
                self.assertEqual(denied_by(self.policy, request), ["DenyOutsideApprovedRegions"])

    def test_approved_regions_are_allowed(self):
        for region in sorted(APPROVED_REGIONS):
            with self.subTest(region=region):
                request = Request("ec2:RunInstances", DEVELOPER, region=region)
                self.assertEqual(denied_by(self.policy, request), [])

    def test_global_services_work_from_any_region_endpoint(self):
        for action in ("iam:CreateRole", "sts:AssumeRole", "route53:ChangeResourceRecordSets",
                       "cloudfront:CreateInvalidation", "support:DescribeCases", "budgets:ViewBudget"):
            with self.subTest(action=action):
                request = Request(action, DEVELOPER, region="eu-west-1")
                self.assertEqual(denied_by(self.policy, request), [])

    def test_management_access_role_is_exempt_for_break_glass(self):
        request = Request("ec2:RunInstances", MANAGEMENT_ACCESS_ROLE, region="eu-west-1")
        self.assertEqual(denied_by(self.policy, request), [])

    def test_region_list_matches_documentation(self):
        condition = self.policy["Statement"][0]["Condition"]["StringNotEquals"]["aws:RequestedRegion"]
        self.assertEqual(set(condition), APPROVED_REGIONS)


class ProtectSecurityBaselineTest(unittest.TestCase):
    policy = load(SCP_DIR / "protect-security-baseline.json")

    # Every action the policy lists, read from the file so a typo or a newly
    # added action is exercised too. The management access role statement is resource
    # scoped and tested separately below.
    TAMPERING = {
        action: statement["Sid"]
        for statement in policy["Statement"]
        if statement["Sid"] != "ProtectDeployRole"
        for action in statement["Action"]
    }

    # Spot checks that fail if an action is renamed or dropped from the file.
    REQUIRED = {
        "cloudtrail:StopLogging": "ProtectCloudTrail",
        "cloudtrail:DeleteTrail": "ProtectCloudTrail",
        "cloudtrail:PutEventSelectors": "ProtectCloudTrail",
        "config:StopConfigurationRecorder": "ProtectConfig",
        "config:DeleteDeliveryChannel": "ProtectConfig",
        "config:DeleteConfigRule": "ProtectConfig",
        "guardduty:DeleteDetector": "ProtectGuardDutyAndSecurityHub",
        "guardduty:DisassociateMembers": "ProtectGuardDutyAndSecurityHub",
        "securityhub:DisableSecurityHub": "ProtectGuardDutyAndSecurityHub",
        "securityhub:BatchDisableStandards": "ProtectGuardDutyAndSecurityHub",
    }

    def test_required_actions_are_listed(self):
        for action, sid in self.REQUIRED.items():
            with self.subTest(action=action):
                self.assertEqual(self.TAMPERING.get(action), sid)

    def test_action_names_are_well_formed(self):
        for action in self.TAMPERING:
            with self.subTest(action=action):
                self.assertRegex(action, r"^(cloudtrail|config|guardduty|securityhub):[A-Z][A-Za-z]+$")

    def test_tampering_is_denied_for_workload_principals(self):
        for principal in (DEVELOPER, PIPELINE):
            for action, sid in self.TAMPERING.items():
                with self.subTest(principal=principal, action=action):
                    self.assertEqual(denied_by(self.policy, Request(action, principal)), [sid])

    def test_management_access_role_can_manage_the_baseline(self):
        for action in self.TAMPERING:
            with self.subTest(action=action):
                self.assertEqual(denied_by(self.policy, Request(action, MANAGEMENT_ACCESS_ROLE)), [])

    def test_reads_stay_allowed(self):
        for action in ("cloudtrail:LookupEvents", "config:DescribeConfigurationRecorders",
                       "guardduty:ListFindings", "securityhub:GetFindings"):
            with self.subTest(action=action):
                self.assertEqual(denied_by(self.policy, Request(action, DEVELOPER)), [])

    def test_management_access_role_cannot_be_modified_by_others(self):
        request = Request("iam:UpdateAssumeRolePolicy", DEVELOPER, resource=MANAGEMENT_ACCESS_ROLE)
        self.assertEqual(denied_by(self.policy, request), ["ProtectDeployRole"])

    def test_management_access_role_can_update_itself(self):
        request = Request("iam:PutRolePolicy", MANAGEMENT_ACCESS_ROLE, resource=MANAGEMENT_ACCESS_ROLE)
        self.assertEqual(denied_by(self.policy, request), [])

    def test_other_roles_can_still_be_managed(self):
        request = Request("iam:PutRolePolicy", DEVELOPER, resource="arn:aws:iam::555555555555:role/storefront-task")
        self.assertEqual(denied_by(self.policy, request), [])

    def test_exemption_names_only_the_management_access_role(self):
        # A broad exemption such as role/* would disable the guardrail.
        for statement in self.policy["Statement"]:
            exempt = statement["Condition"]["ArnNotLike"]["aws:PrincipalArn"]
            with self.subTest(sid=statement["Sid"]):
                self.assertEqual(exempt, "arn:aws:iam::*:role/OrganizationAccountAccessRole")


class EvaluatorTest(unittest.TestCase):
    """The evaluator must refuse grammar it does not model."""

    def test_unknown_operator_raises(self):
        policy = {"Statement": [{"Sid": "X", "Effect": "Deny", "Action": "*", "Resource": "*",
                                 "Condition": {"IpAddress": {"aws:SourceIp": "192.0.2.0/24"}}}]}
        with self.assertRaises(UnsupportedPolicy):
            denied_by(policy, Request("s3:GetObject", DEVELOPER))

    def test_allow_statement_raises(self):
        policy = {"Statement": [{"Sid": "X", "Effect": "Allow", "Action": "*", "Resource": "*"}]}
        with self.assertRaises(UnsupportedPolicy):
            denied_by(policy, Request("s3:GetObject", DEVELOPER))


if __name__ == "__main__":
    unittest.main()
