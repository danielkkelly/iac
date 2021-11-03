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
  name          = "alias/${var.env}-config-sns"
  target_key_id = aws_kms_key.config_sns_kms_key.id
}

resource "aws_kms_key" "config_sns_kms_key" {
  description         = "KMS key for AWS Config SNS"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.sns_kms_key_policy.json

  tags = {
    Name = "platform-config-sns"
  }
}