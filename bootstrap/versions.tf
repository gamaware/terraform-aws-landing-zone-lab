terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bootstrap starts with local state because the bucket does not exist yet.
  # After the first apply, uncomment the backend, run
  # `terraform init -migrate-state -backend-config=../environments/backend.hcl` and delete
  # the local state file.
  # backend "s3" {
  #   key = "bootstrap/terraform.tfstate"
  # }
}
