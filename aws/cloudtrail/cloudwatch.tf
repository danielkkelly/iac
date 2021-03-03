resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "cloudtrail"
  retention_in_days = 90
}

data "aws_iam_policy_document" "log_policy" {
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_log_group.name}:log-stream:*"
    ]
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_events_role" {
  name               = "platform-cloudtrail-cloudwatch-events-role"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_role_policy" "policy" {
  name   = "platform-cloudtrail-cloudwatch-events-role-policy"
  policy = data.aws_iam_policy_document.log_policy.json
  role   = aws_iam_role.cloudtrail_cloudwatch_events_role.id
}
