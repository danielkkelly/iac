/*
 * KMS key for SNS topic encryption
 */
data "aws_iam_policy_document" "cloudwatch_alarm_sns_kms_key_policy" {

  policy_id = "CloudWatch Alarm Key Policy"

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
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

module "cloudwatch_alarms_sns_kms_key" {
  source = "../kms-key"
  env    = var.env
  name   = "sns-cloudwatch-alarms"
  policy = data.aws_iam_policy_document.cloudwatch_alarm_sns_kms_key_policy.json
}