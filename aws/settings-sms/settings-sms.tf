terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.default, aws.replica ]
    }
  }
}

data "aws_iam_role" "delivery_status_role" {
  provider = aws.default
  name = "platform-${var.env}-sns-cloudwatch-logs-role"
}

resource "aws_sns_sms_preferences" "sms_preferences" {
  provider = aws.default
  default_sender_id                     = var.default_sender_id
  default_sms_type                      = var.default_sms_type
  delivery_status_iam_role_arn          = data.aws_iam_role.delivery_status_role.arn
  delivery_status_success_sampling_rate = var.delivery_status_success_sampling_rate
  monthly_spend_limit                   = var.monthly_spend_limit
  usage_report_s3_bucket                = module.delivery_status_s3_bucket.bucket
}