provider "aws" {
  region  = var.region
  profile = var.env
}

/*
 * The following resources create a role for AWS support access to allow authorized 
 * users to manage AWS support incidents.  This satisfies the iam-policy-in-use
 * AWS config rule.
 */
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "aws_support_role" {
  name               = "${var.env}-aws-support-role"
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

resource "aws_iam_role_policy_attachment" "aws_support_role_policy_attachment" {
  role       = aws_iam_role.aws_support_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSupportAccess"
}

/*
 * The following resources create a policy and group acess for developers who have
 * API access.  It also creates users with AWS access 
 */
resource "aws_iam_policy" "net_policy" {
  name   = "${var.env}-net"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Deny",
        "Action": "*",
        "Resource": "*",
        "Condition": {
            "NotIpAddress": {
                "aws:SourceIp": [
                  ${var.networks}
                ]
            },
            "Bool": {"aws:ViaAWSService": "false"}
        }
    }
}
EOF
}

/* 
 * Policy for the average development user.
 */
resource "aws_iam_policy" "dev_policy" {
  name        = "${var.env}-dev"
  path        = "/"
  description = "EC2, ECR, EKS, session manager permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ec2:DescribeInstances",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImages",
        "ecr:DescribeImageScanFindings",
        "ecr:DescribeRegistry",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRegistryPolicy",
        "ecr:GetRepositoryPolicy",
        "ecr:TagResource",
        "ecr:UntagResource",
        "ecr:BatchDeleteImage",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:PutImageTagMutability",
        "ecr:ReplicateImage",
        "ecr:StartImageScan",
        "ecr:StartLifecyclePolicyPreview",
        "ecr:UploadLayerPart",
        "eks:ListClusters",
        "eks:DescribeCluster",
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ssm:DescribeInstanceProperties"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
        "Sid": "SessionManagerStartSession",
        "Effect": "Allow",
        "Action": [
            "ssm:StartSession"
        ],
        "Resource": [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ssm:*::document/AWS-StartSSHSession"
        ],
        "Condition": {
          "StringEquals": {
            "ssm:resourceTag/HostType": "bastion"
          }
        }
    },
    {
      "Sid": "SessionManagerPortForward",
      "Effect": "Allow",
      "Action": "ssm:StartSession",
      "Resource": "arn:aws:ssm:*::document/AWS-StartSSHSession"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ssm:TerminateSession",
            "ssm:ResumeSession"
        ],
        "Resource": [
            "arn:aws:ssm:*:*:session/$${aws:username}-*"
        ]
    }
  ]
}
EOF
}

/*
 * The following resources create a dev and dev admin group and attach the policies
 * created above to them.  First create the dev group with teh associated policy
 * attachments.
 */
resource "aws_iam_group" "dev_group" {
  name = "${var.env}-dev"
}

resource "aws_iam_group_policy_attachment" "dev_policy_attachment" {
  group      = aws_iam_group.dev_group.name
  policy_arn = aws_iam_policy.dev_policy.arn
}

resource "aws_iam_group_policy_attachment" "dev_net_policy_attachment" {
  group      = aws_iam_group.dev_group.name
  policy_arn = aws_iam_policy.net_policy.arn
}

/*
 * Create the dev-admin group and policy attachment.  Only create the group
 * if there are actually users in dev-admin.  Otherwise we have a group without
 * users which trips iam-group-has-users-check.
 */
locals {
  has_dev_admin = contains(flatten(values(var.users_groups)), "dev-admin")
}

resource "aws_iam_group" "dev_admin_group" {
  count = local.has_dev_admin ? 1 : 0
  name  = "${var.env}-dev-admin"
}

resource "aws_iam_group_policy_attachment" "dev_admin_policy_attachment" {
  count      = local.has_dev_admin ? 1 : 0
  group      = aws_iam_group.dev_admin_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "dev_admin_net_policy_attachment" {
  count      = local.has_dev_admin ? 1 : 0
  group      = aws_iam_group.dev_admin_group[0].name
  policy_arn = aws_iam_policy.net_policy.arn
}

resource "aws_iam_user" "user" {
  for_each      = var.users_groups
  name          = "${each.key}.${var.env}"
  force_destroy = true
}

resource "aws_iam_access_key" "user_access_key" {
  for_each   = var.users_groups
  user       = "${each.key}.${var.env}"
  pgp_key    = file("${var.iac_home}/keys/${each.key}-gpg.pub")
  depends_on = [aws_iam_user.user]
}

/* 
 * The following lines loop through the users and groups in var.users_groups to 
 * create them in IAM.
 */
resource "aws_iam_user_group_membership" "dev_ugm" {
  for_each = var.users_groups
  user     = "${each.key}.${var.env}"
  groups = [
    for group in each.value : "${var.env}-${group}"
  ]
  depends_on = [
    aws_iam_user.user,
    aws_iam_group.dev_group,
    aws_iam_group.dev_admin_group
  ]
}