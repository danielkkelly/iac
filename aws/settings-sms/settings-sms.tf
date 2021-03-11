data "aws_iam_role" "delivery_status_role" {
  name = "platform-sns-cloudwatch-logs"
}

resource "aws_sns_sms_preferences" "sms_preferences" {
  default_sender_id                     = var.default_sender_id
  default_sms_type                      = var.default_sms_type
  delivery_status_iam_role_arn          = data.aws_iam_role.delivery_status_role.arn
  delivery_status_success_sampling_rate = var.delivery_status_success_sampling_rate
  monthly_spend_limit                   = var.monthly_spend_limit
  usage_report_s3_bucket                = module.delivery_status_s3_bucket.bucket
}