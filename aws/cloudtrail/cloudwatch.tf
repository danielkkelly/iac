module "cloudtrail_lg" {
  source = "../cloudwatch-log-group"
  region = var.region
  env    = var.env
  name   = "cloudtrail"
}

data "aws_iam_policy_document" "log_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${module.cloudtrail_lg.name}:log-stream:*"
    ]
  }
}

resource "aws_iam_policy" "log_policy" {
  name   = "platform-${var.env}-cloudtrail-cloudwatch-log-policy"
  policy = data.aws_iam_policy_document.log_policy_document.json
}

data "aws_iam_policy_document" "assume_role_policy" {
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
  name               = "platform-${var.env}-cloudtrail-cloudwatch-events-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "events_role_policy_attachment" {
  role       = aws_iam_role.cloudtrail_cloudwatch_events_role.id
  policy_arn = aws_iam_policy.log_policy.arn
}
