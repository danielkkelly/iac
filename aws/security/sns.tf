data "aws_caller_identity" "current" {}

data "aws_kms_key" "config_sns_kms_key" {
  key_id = "alias/${var.env}-config-sns"
}

/*
 * SNS topic
 */
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid = "Allow source owner various operations"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Publish",
      "SNS:Receive",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.config_sns_topic.arn
    ]
  }
}

resource "aws_sns_topic" "config_sns_topic" {
  display_name = "platform-${var.env}-config-topic"
  name         = "platform-${var.env}-config-topic"

  kms_master_key_id = data.aws_kms_key.config_sns_kms_key.id
}

resource "aws_sns_topic_policy" "config_sns_topic_policy" {
  arn = aws_sns_topic.config_sns_topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

/* 
 * For notification via SNS 
 */
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