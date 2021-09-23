resource "aws_iam_group" "user_group" {
    name = aws_iam_user.user.name
}

resource "aws_iam_group_policy_attachment" "dev_manage_mfa_policy_attachment" {
  group = aws_iam_group.user_group.name
  policy_arn = aws_iam_policy.dev_manage_mfa_policy.arn
}

resource "aws_iam_group_policy_attachment" "dev_manage_credentials_policy_attachment" {
  group = aws_iam_group.user_group.name
  policy_arn = aws_iam_policy.dev_manage_credentials_policy.arn
}

resource "aws_iam_user_group_membership" "user_group_membership" {
  user = aws_iam_user.user.name
  groups = concat([aws_iam_group.user_group.name], var.groups)
}
