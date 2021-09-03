data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "delivery_status_policy_document" {
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

resource "aws_iam_policy" "delivery_status_policy" {
  name   = "platform-${var.env}-sns-cloudwatch-logs-policy"
  policy = data.aws_iam_policy_document.delivery_status_policy_document.json
}

data "aws_iam_policy_document" "publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_policy" "publish" {
  name        = "platform-${var.env}-sms-publish-policy"
  description = "Allow publishing to Group SMS SNS Topic"
  policy      = data.aws_iam_policy_document.publish.json
}

resource "aws_iam_role" "delivery_status_role" {
  description        = "Allow AWS to publish SMS delivery status logs"
  name               = "platform-${var.env}-sns-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "delivery_status_role_policy_attachment" {
  role       = aws_iam_role.delivery_status_role.id
  policy_arn = aws_iam_policy.delivery_status_policy.arn
}