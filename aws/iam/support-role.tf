/*
 * The following resources create a role for AWS support access to allow authorized 
 * users to manage AWS support incidents.  This satisfies the iam-policy-in-use
 * AWS config rule.
 */
resource "aws_iam_role" "aws_support_role" {
  name               = "${var.env}-aws-support-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_trust_account_policy_document.json
  /*<<EOF
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
EOF*/
}

resource "aws_iam_role_policy_attachment" "aws_support_role_policy_attachment" {
  role       = aws_iam_role.aws_support_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSupportAccess"
}