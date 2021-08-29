data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cloudwatch_key_policy" {
  statement {
    actions   = ["kms:*"]
    effect    = "Allow"
    sid       = "Allow root user to manage the KMS key and enable IAM policies to allow access to the key."
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    effect    = "Allow"
    resources = ["*"]

    principals {
      identifiers = ["logs.${var.region}.amazonaws.com"]
      type        = "Service"
    }

    condition {
      variable = "kms:EncryptionContext:aws:logs:arn"
      test     = "ArnEquals"
      values   = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

/**
 * Alias for the KMS key
 */
resource "aws_kms_alias" "main" {
  name          = "alias/${var.env}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch_kms_key.id
}

/**
 * The KMS key.
 */
resource "aws_kms_key" "cloudwatch_kms_key" {
  description         = "KMS key for CloudWatch"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.cloudwatch_key_policy.json

  tags = {
    Name = "platform-cloudwatch"
  }
}