# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "network" {
  source = "../.."

  name               = "example"
  cidr_block         = "10.30.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  nat_gateway_mode   = "none"
}
