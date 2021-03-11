data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "delivery_status_role_inline_policy" {
  statement {
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy",
    ]
  }
}

data "aws_iam_policy_document" "publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_policy" "publish" {
  name        = var.policy_name
  path        = var.policy_path
  description = "Allow publishing to Group SMS SNS Topic"
  policy      = data.aws_iam_policy_document.publish.json
}

resource "aws_iam_role" "delivery_status_role" {
  description        = "Allow AWS to publish SMS delivery status logs"
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "delivery_status_role_inline_policy" {
  name   = "${aws_iam_role.delivery_status_role.name}InlinePolicy"
  role   = aws_iam_role.delivery_status_role.id
  policy = data.aws_iam_policy_document.delivery_status_role_inline_policy.json
}