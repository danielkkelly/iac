provider "aws" {
  region  = var.region
  profile = var.env
}

resource "aws_iam_policy" "net_policy" {
  name        = "${var.env}-net"
  path        = "/"
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
                  "${var.networks}"
                ]
            },
            "Bool": {"aws:ViaAWSService": "false"}
        }
    }
}
EOF
}

# The following resources create a policy and group acess for developers who have
# API access.  It also creates users with AWS access 

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
        "ecr:*",
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

resource "aws_iam_group" "dev_admin_group" {
  name = "${var.env}-dev-admin"
}

resource "aws_iam_group_policy_attachment" "dev_admin_policy_attachment" {
  group      = aws_iam_group.dev_admin_group.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "dev_admin_net_policy_attachment" {
  group      = aws_iam_group.dev_admin_group.name
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

resource "aws_iam_user_group_membership" "dev_ugm" {
  for_each = var.users_groups
  user     = "${each.key}.${var.env}"
  groups = [
    for group in each.value: "${var.env}-${group}"
  ]
  depends_on = [
                aws_iam_user.user, 
                aws_iam_group.dev_group, 
                aws_iam_group.dev_admin_group
               ]
}