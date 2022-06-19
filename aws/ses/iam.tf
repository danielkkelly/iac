resource "aws_iam_user" "smtp_user" {
  name = "smtp.${var.env}"
}

resource "aws_iam_access_key" "smtp_user_access_key" {
  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "ses_iam_policy_document" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_iam_policy" {
  name        = "${var.env}-ses"
  description = "Allows sending email via Simple Email Service"
  policy      = data.aws_iam_policy_document.ses_iam_policy_document.json
}

//TODO: eliminate direct policy attachment and instead tie to a group for compliance
resource "aws_iam_user_policy_attachment" "smtp_user_policy_attachment" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_iam_policy.arn
}