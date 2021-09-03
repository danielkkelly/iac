data "aws_caller_identity" "current" {}


/*
 * KMS key for SNS topic encryption
 */
data "aws_iam_policy_document" "sns_kms_key_policy" {

  policy_id = "Config Key Policy"

  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_kms_alias" "config_sns_kms_alias" {
  name          = "alias/${var.env}-sns"
  target_key_id = aws_kms_key.config_sns_kms_key.id
}

resource "aws_kms_key" "config_sns_kms_key" {
  description         = "KMS key for AWS Config SNS"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.sns_kms_key_policy.json

  tags = {
    Name = "platform-config"
  }
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

  kms_master_key_id = aws_kms_key.config_sns_kms_key.id
}

resource "aws_sns_topic_policy" "config_sns_topic_policy" {
  arn    = aws_sns_topic.config_sns_topic.arn

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