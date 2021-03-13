provider "aws" {
  region  = var.region
  profile = var.env
}

# SMS
variable "sms_subscription" {
    default = false
}
variable "sms_number" {}
