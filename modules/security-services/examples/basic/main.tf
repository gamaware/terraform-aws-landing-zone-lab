# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "security_services" {
  source = "../.."
}
