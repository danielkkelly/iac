data "aws_iam_policy_document" "backup_service_assume_role_policy_document" {
  statement {
    sid     = "AssumeServiceRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

/* The policies that allow the backup service to take backups and restores */
data "aws_iam_policy" "backup_service_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

data "aws_iam_policy" "restore_service_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

data "aws_caller_identity" "current" {}

/* Needed to allow the backup service to restore from a snapshot to an EC2 instance
 See https://stackoverflow.com/questions/61802628/aws-backup-missing-permission-iampassrole */
data "aws_iam_policy_document" "pass_role_policy_document" {
  statement {
    sid       = "ExamplePassRole"
    actions   = ["iam:PassRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"]
  }
}

/* Roles for taking AWS Backups */
resource "aws_iam_role" "backup_service_role" {
  name               = "ExampleAWSBackupServiceRole"
  description        = "Allows the AWS Backup Service to take scheduled backups"
  assume_role_policy = data.aws_iam_policy_document.backup_service_assume_role_policy_document.json

  tags = {
    project = "platform"
    role    = "iam"
  }
}

resource "aws_iam_role_policy" "backup_service_backup_role_policy" {
  policy = data.aws_iam_policy.backup_service_policy.policy
  role   = aws_iam_role.backup_service_role.name
}

resource "aws_iam_role_policy" "restore_service_backup_role-policy" {
  policy = data.aws_iam_policy.restore_service_policy.policy
  role   = aws_iam_role.backup_service_role.name
}

resource "aws_iam_role_policy" "backup_service_pass_role_policy" {
  policy = data.aws_iam_policy_document.pass_role_policy_document.json
  role   = aws_iam_role.backup_service_role.name
}