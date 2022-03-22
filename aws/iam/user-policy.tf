/* 
 * Assume role policy that creates a trust relationship with the account from another
 * role
 */
data "aws_iam_policy_document" "assume_role_trust_account_policy_document" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}


/*
 * The following resources create a policy and group acess for developers who have
 * API access.  It also creates users with AWS access 
 */
resource "aws_iam_policy" "net_policy" {
  name   = "${var.env}-net-policy"
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
 * Assigned to users through groups to allow the user to assume the specific role
 */
resource "aws_iam_policy" "dev_assume_role_policy" {
  name   = "${var.env}-dev-assume-role-policy"
  path   = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "${aws_iam_role.dev_assume_role.arn}",
    "Condition": {
      "Bool": {
        "aws:MultiFactorAuthPresent": "true"
      }
    }
  }
}
EOF
}

/* 
 * Read-write policy for the average development user.
 */
resource "aws_iam_policy" "dev_policy" {
  name        = "${var.env}-dev-policy"
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
        "eks:ListFargateProfiles",
        "eks:ListNodeGroups",
        "eks:ListUpdates",
        "eks:AccessKubernetesApi",
        "eks:DescribeCluster",
        "eks:DescribeFargateProfile",
        "eks:DescribeNodegroup",
        "eks:DescribeUpdate",
        "eks:ListTagsForResource",
        "eks:TagResource",
        "eks:UntagResource",
        "ssm:GetParameter",
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

resource "aws_iam_policy" "dev_admin_assume_role_policy" {
  name   = "${var.env}-dev-admin-assume-role-policy"
  path   = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "${aws_iam_role.dev_admin_assume_role.arn}",
    "Condition": {
      "Bool": {
        "aws:MultiFactorAuthPresent": "true"
      }
    }
  }
}
EOF
}