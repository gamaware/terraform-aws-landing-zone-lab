# Offline tests with a mocked AWS provider.

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
  name                  = "harbor-goods-shared"
  cidr_block            = "10.20.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b"]
  share_with_principals = ["arn:aws:organizations::111122223333:ou/o-exampleorgid/ou-examplerootid111-exampleouid111"]
}

run "single_nat_layout" {
  command = plan

  assert {
    condition     = output.private_subnet_cidrs["us-east-1a"] == "10.20.32.0/20" && output.private_subnet_cidrs["us-east-1b"] == "10.20.48.0/20"
    error_message = "Private subnets take the /20 slots after the public ones."
  }

  assert {
    condition     = toset([for s in aws_subnet.public : s.cidr_block]) == toset(["10.20.0.0/20", "10.20.16.0/20"])
    error_message = "Public subnets take the first /20 slots."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && output.nat_gateway_count == 1
    error_message = "single mode creates exactly one NAT gateway."
  }

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "Every private route table needs a default route."
  }

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL"
    error_message = "Flow logs must capture accepted and rejected traffic."
  }

  assert {
    condition     = aws_ram_resource_share.private_subnets[0].allow_external_principals == false
    error_message = "Subnets must only be shared inside the organization."
  }

  assert {
    condition     = length(aws_ram_resource_association.private_subnets) == 2
    error_message = "Both private subnets are shared; public subnets are not."
  }
}

run "per_az_nat" {
  command = plan

  variables {
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    nat_gateway_mode   = "per_az"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "per_az mode creates one NAT gateway per zone."
  }
}

run "private_only" {
  command = plan

  variables {
    nat_gateway_mode      = "none"
    share_with_principals = []
  }

  assert {
    condition     = length(aws_internet_gateway.this) == 0 && length(aws_subnet.public) == 0 && length(aws_nat_gateway.this) == 0
    error_message = "none mode has no internet path at all."
  }

  assert {
    condition     = length(aws_ram_resource_share.private_subnets) == 0
    error_message = "No RAM share without principals."
  }
}

run "rejects_non_16_cidr" {
  command = plan

  variables {
    cidr_block = "10.20.0.0/24"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_single_az" {
  command = plan

  variables {
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [var.availability_zones]
}
