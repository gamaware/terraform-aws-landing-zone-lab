locals {
  stack = "security-services"
}

module "security_services" {
  source = "../../../../modules/security-services"

  guardduty_finding_frequency = "FIFTEEN_MINUTES"
}
