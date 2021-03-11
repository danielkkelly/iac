provider "aws" {
  region  = var.region
  profile = var.env
}

module "settings-sms" {
  count                  = var.sms_enabled ? 1 : 0
  source                 = "../settings-sms"
  monthly_spend_limit    = 1
  usage_report_s3_bucket = "platform-sms-usage"
  env                    = var.env
}