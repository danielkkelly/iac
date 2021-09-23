/* 
 * Developer 
 */
resource "aws_iam_role" "dev_assume_role" {
  name               = "platform-${var.env}-dev-role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dev_assume_role_policy_attachment" {
  role       = aws_iam_role.dev_assume_role.name
  policy_arn = aws_iam_policy.dev_policy.arn
}

/*
resource "aws_iam_role_policy_attachment" "require_mfa_policy" {
  role       = aws_iam_role.dev_rw_assume_role.name
  policy_arn = aws_iam_policy.require_mfa_policy.arn
}*/

/*
 * Dev Admin
 */
resource "aws_iam_role" "dev_admin_assume_role" {
  name               = "platform-${var.env}-dev-admin-role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dev_admin_assume_role_policy_attachment" {
  role       = aws_iam_role.dev_admin_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
