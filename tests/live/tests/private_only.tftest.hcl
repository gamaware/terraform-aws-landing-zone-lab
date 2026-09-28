# Live tests run private-only. The live root must build a VPC with no internet path: no internet
# gateway, no public subnets, no NAT gateway and therefore no Elastic IP. scripts/test-live.sh
# also refuses a saved plan with internet-facing resources (scripts/check_private_plan.py).

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  account_id = "123456789012"
  suffix     = "offline"
}

run "live_root_has_no_internet_path" {
  command = plan

  assert {
    condition     = module.network.nat_gateway_count == 0
    error_message = "The live test must not create NAT gateways or their Elastic IPs."
  }

  assert {
    condition     = length(module.network.public_subnet_ids) == 0
    error_message = "The live test must not create public subnets or an internet gateway."
  }
}
