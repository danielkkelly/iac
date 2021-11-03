provider "aws" {
  region  = var.region
  profile = var.env
}

provider "aws" {
  alias  = "replica"
  region = var.replication_region
  profile = var.env
}

module "settings-sms" {
  //count                  = var.sms_enabled ? 1 : 0
  source                 = "../settings-sms"
  monthly_spend_limit    = 1
  usage_report_s3_bucket = "sms-usage"
  env                    = var.env
  providers = {
    aws.default = aws
    aws.replica = aws.replica
  }
}