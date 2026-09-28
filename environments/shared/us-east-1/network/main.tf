locals {
  stack = "network"
}

module "network" {
  source = "../../../../modules/network"

  name                  = "harbor-goods-shared"
  cidr_block            = "10.20.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b"]
  nat_gateway_mode      = var.nat_gateway_mode
  share_with_principals = [var.workloads_ou_arn]
}
