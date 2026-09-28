# Minimal usage with example values. Validated offline by make verify.

provider "aws" {
  region = var.region
}

module "pipeline_role" {
  source = "../.."

  github_subjects = ["repo:harbor-goods/storefront:environment:production"]
}
