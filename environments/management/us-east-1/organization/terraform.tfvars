# Example values only (AWS documentation account IDs, example.com addresses).
account_id = "111122223333"

accounts = {
  log-archive = {
    name  = "harbor-goods-log-archive"
    email = "aws-log-archive@example.com"
    ou    = "Security"
  }
  security = {
    name  = "harbor-goods-security"
    email = "aws-security@example.com"
    ou    = "Security"
  }
  shared = {
    name  = "harbor-goods-shared"
    email = "aws-shared@example.com"
    ou    = "Infrastructure"
  }
  workloads = {
    name  = "harbor-goods-workloads"
    email = "aws-workloads@example.com"
    ou    = "Workloads"
  }
}
