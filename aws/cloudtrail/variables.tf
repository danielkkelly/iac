# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

# Cloudwatch
variable "cloudwatch_retention_in_days" {
  default = 365
}

# SMS
variable "sms_enabled" {
  default = false
}
variable "sms_number" {}