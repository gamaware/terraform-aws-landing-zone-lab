"""Live tests run private-only: scripts/check_private_plan.py must refuse any saved plan that
would create an internet-facing resource. scripts/test-live.sh runs it before `terraform apply`."""

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("check_private_plan", ROOT / "scripts" / "check_private_plan.py")
check_private_plan = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(check_private_plan)


def plan(*changes, actions=("create",)):
    return {
        "resource_changes": [
            {"address": f"{kind}.test{i}", "type": kind, "change": {"actions": list(actions), "after": after}}
            for i, (kind, after) in enumerate(changes)
        ]
    }


PUBLIC = [
    ("aws_lb", {"internal": False}),
    ("aws_security_group", {"ingress": [{"cidr_blocks": ["0.0.0.0/0"]}]}),
    ("aws_security_group", {"ingress": [{"ipv6_cidr_blocks": ["::/0"]}]}),
    ("aws_default_security_group", {"ingress": [{"cidr_blocks": ["0.0.0.0/0"]}]}),
    ("aws_security_group_rule", {"type": "ingress", "cidr_blocks": ["0.0.0.0/0"]}),
    ("aws_vpc_security_group_ingress_rule", {"cidr_ipv4": "0.0.0.0/0"}),
    ("aws_instance", {"associate_public_ip_address": True}),
    ("aws_launch_template", {"network_interfaces": [{"associate_public_ip_address": "true"}]}),
    ("aws_subnet", {"map_public_ip_on_launch": True}),
    ("aws_eip", {"domain": "vpc"}),
    ("aws_db_instance", {"publicly_accessible": True}),
    ("aws_s3_bucket_public_access_block", {"block_public_acls": True, "block_public_policy": False}),
    ("aws_lambda_function_url", {"authorization_type": "NONE"}),
    ("aws_eks_cluster", {"vpc_config": [{"endpoint_public_access": True, "public_access_cidrs": ["203.0.113.10/32"]}]}),
]


class CheckPrivatePlanTest(unittest.TestCase):
    def test_refuses_each_internet_facing_resource(self):
        for kind, after in PUBLIC:
            with self.subTest(kind=kind, after=after):
                self.assertTrue(check_private_plan.findings(plan((kind, after))))

    def test_accepts_the_live_test_shape(self):
        live = plan(
            ("aws_vpc", {"cidr_block": "10.99.0.0/16"}),
            ("aws_subnet", {"map_public_ip_on_launch": False}),
            ("aws_default_security_group", {"ingress": [], "egress": []}),
            (
                "aws_s3_bucket_public_access_block",
                {
                    "block_public_acls": True,
                    "block_public_policy": True,
                    "ignore_public_acls": True,
                    "restrict_public_buckets": True,
                },
            ),
            ("aws_iam_role", {}),
            ("aws_budgets_budget", {}),
        )
        self.assertEqual(check_private_plan.findings(live), [])

    def test_ignores_deletes(self):
        self.assertEqual(check_private_plan.findings(plan(("aws_lb", {}), actions=("delete",))), [])


if __name__ == "__main__":
    unittest.main()
