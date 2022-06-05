provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_caller_identity" "current" {}

data "aws_kms_key" "sns_kms_key" {
  key_id = "alias/${var.env}-sns-cloudwatch-alarms"
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
      aws_sns_topic.sns_topic.arn
    ]
  }
  statement {
    sid = "Allow Cloudwatch"

    actions = [
      "SNS:Publish"
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.sns_topic.arn
    ]
  }
}

resource "aws_sns_topic" "sns_topic" {
  display_name = "platform-${var.env}-cloudwatch-alarm-topic"
  name         = "platform-${var.env}-cloudwatch-alarm-topic"

  kms_master_key_id = data.aws_kms_key.sns_kms_key.id
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}