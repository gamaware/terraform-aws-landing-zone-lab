# Shared S3 backend settings. Each stack sets its own key in versions.tf.
# Example values only; the bucket comes from the bootstrap stack output.
bucket       = "harbor-goods-tfstate-111122223333"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
