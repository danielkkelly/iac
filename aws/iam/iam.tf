provider "aws" {
  region  = var.region
  profile = var.env
}
data "aws_caller_identity" "current" {}

/*
 * The following resources create a dev and dev admin group and attach the policies
 * created above to them.  First create the dev group with teh associated policy
 * attachments.
 */
resource "aws_iam_group" "dev_group" {
  name = "${var.env}-dev"
}

resource "aws_iam_group_policy_attachment" "dev_assume_role_policy_attachment" {
  group      = aws_iam_group.dev_group.name
  policy_arn = aws_iam_policy.dev_assume_role_policy.arn
}

resource "aws_iam_group_policy_attachment" "dev_net_policy_attachment" {
  group      = aws_iam_group.dev_group.name
  policy_arn = aws_iam_policy.net_policy.arn
}

resource "aws_iam_group" "dev_admin_group" {
  name = "${var.env}-dev-admin"
}

resource "aws_iam_group_policy_attachment" "dev_admin_assume_role_policy_attachment" {
  group      = aws_iam_group.dev_admin_group.name
  policy_arn = aws_iam_policy.dev_admin_assume_role_policy.arn
}

resource "aws_iam_group_policy_attachment" "dev_admin_net_policy_attachment" {
  group      = aws_iam_group.dev_admin_group.name
  policy_arn = aws_iam_policy.net_policy.arn
}

module "user" {
  for_each = var.users_groups
  source   = "../user"

  iac_home = var.iac_home
  env      = var.env

  username = each.key
  groups = [
    for group in each.value : "${var.env}-${group}"
  ]
}