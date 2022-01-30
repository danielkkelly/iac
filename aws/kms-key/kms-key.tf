data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "default" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "kms_key" {
  description         = "platform-${var.name}"
  enable_key_rotation = true

  policy = var.policy == null ? data.aws_iam_policy_document.default.json : var.policy

  tags = {
    Name = "platform-${var.name}"
  }
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.env}-${var.name}"
  target_key_id = aws_kms_key.kms_key.id
}