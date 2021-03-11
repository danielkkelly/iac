
resource "aws_sns_topic" "config_sns_topic" {
  display_name = "platform-config-topic"
  name         = "platform-config-topic"
}

module "sns_subscription" {
  count  = var.sms_enabled ? 1 : 0
  source = "../sns-subscription"

  topic_arn = aws_sns_topic.config_sns_topic.arn

  subscriptions = [
    {
      protocol = "sms"
      endpoint = var.sms_number
    }
  ]
}