// https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_iam_mfa-selfmanage.html
// https://aws.amazon.com/premiumsupport/knowledge-center/mfa-iam-user-aws-cli/

resource "aws_iam_policy" "dev_manage_mfa_policy" {
  name        = "${local.username}-manage-mfa-policy"
  path        = "/"
  description = "Allow users to manage their own MFA"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListActions",
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers",
        "iam:ListVirtualMFADevices"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
      "Effect": "Allow",
      "Action": [
        "iam:ListMFADevices"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/*",
        "arn:aws:iam::*:user/${local.username}"
      ]
    },
    {
      "Sid": "AllowIndividualUserToManageTheirOwnMFA",
      "Effect": "Allow",
      "Action": [
        "iam:CreateVirtualMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ResyncMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/${local.username}",
        "arn:aws:iam::*:user/${local.username}"
      ]
    },
    {
      "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA",
      "Effect": "Allow",
      "Action": [
        "iam:DeactivateMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/${local.username}",
        "arn:aws:iam::*:user/${local.username}"
      ],
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    },
    {
      "Sid": "BlockMostAccessUnlessSignedInWithMFA",
      "Effect": "Deny",
      "NotAction": [
        "iam:CreateVirtualMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:ListVirtualMFADevices",
        "iam:EnableMFADevice",
        "iam:ResyncMFADevice",
        "iam:ListAccountAliases",
        "iam:ListUsers",
        "iam:ListSSHPublicKeys",
        "iam:ListAccessKeys",
        "iam:ListServiceSpecificCredentials",
        "iam:ListMFADevices",
        "iam:GetAccountSummary",
        "sts:GetSessionToken"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false",
          "aws:ViaAWSService": "false"
        }
      }
    }
  ]
}
EOF
}

// https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_iam_credentials_console.html

resource "aws_iam_policy" "dev_manage_credentials_policy" {
  name        = "${local.username}-manage-creds-policy"
  path        = "/"
  description = "Allow users to rotate their own credentials"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers",
                "iam:GetAccountPasswordPolicy"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:*AccessKey*",
                "iam:ChangePassword",
                "iam:GetUser",
                "iam:*ServiceSpecificCredential*",
                "iam:*SigningCertificate*"
            ],
            "Resource": ["arn:aws:iam::*:user/${local.username}"]
        }
    ]
}
EOF
}