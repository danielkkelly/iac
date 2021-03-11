provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "cloudtrail" {
  name           = "platform-cloudtrail"
  s3_bucket_name = module.cloudtrail_s3_bucket.bucket

  include_global_service_events = true
  is_multi_region_trail         = true

  enable_logging             = true
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_events_role.arn

  kms_key_id = aws_kms_key.cloudtrail_kms_key.arn
}

module "cloudtrail_api_alarms" {
  name           = "cloudtrail-alarms"
  source         = "git::https://github.com/cloudposse/terraform-aws-cloudtrail-cloudwatch-alarms.git"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  kms_master_key_id = aws_kms_key.cloudtrail_kms_key.id

  sns_policy_enabled = false
}

module "sns_subscription" {
  count  = var.sms_enabled ? 1 : 0
  source = "../sns-subscription"

  topic_arn = module.cloudtrail_api_alarms.sns_topic_arn

  subscriptions = [
    {
      protocol = "sms"
      endpoint = var.sms_number
    }
  ]
}