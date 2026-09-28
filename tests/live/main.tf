# Live test root. Deploys only resources that are safe to create and delete in
# a single sandbox account: no AWS Organizations, no accounts, no SCPs, no
# Identity Center and no organization trail. scripts/test-live.sh applies it,
# checks the result and destroys it in the same run.

terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # The script passes a state path in a temporary directory outside the repo.
  backend "local" {}
}

provider "aws" {
  region  = var.region
  profile = var.profile

  allowed_account_ids = [var.account_id]

  default_tags {
    tags = {
      purpose = "portfolio-test"
      run     = var.suffix
      Project = "landing-zone"
    }
  }
}

module "log_archive" {
  source = "../../modules/log-archive"

  bucket_name              = "lz-live-${var.suffix}"
  organization_id          = "o-exampleorgid"
  management_account_id    = var.account_id
  deny_object_deletion     = false
  force_destroy            = true
  kms_deletion_window_days = 7
}

module "network" {
  source = "../../modules/network"

  name               = "lz-live-${var.suffix}"
  cidr_block         = "10.99.0.0/16"
  availability_zones = ["${var.region}a", "${var.region}b"]
  nat_gateway_mode   = "none"
}

module "pipeline_role" {
  source = "../../modules/pipeline-role"

  role_name         = "lz-live-${var.suffix}"
  github_subjects   = ["repo:harbor-goods/storefront:environment:production"]
  oidc_provider_arn = var.oidc_provider_arn
}

module "budgets" {
  source = "../../modules/budgets"

  subscriber_emails = [var.alert_email]

  budgets = {
    "lz-live-${var.suffix}" = {
      limit_usd  = 1
      account_id = var.account_id
    }
  }
}
