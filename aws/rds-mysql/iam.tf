/*
 * Roles, policy, and policy attachment for 
 */

resource "aws_iam_role" "rds_enhanced_monitoring_iam_role" {
  name_prefix        = "platform-rds-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring_policy_document.json
}

data "aws_iam_policy_document" "rds_enhanced_monitoring_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_policy_attachment" {
  role       = aws_iam_role.rds_enhanced_monitoring_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

/*
 * This policy will allow access to only the database cluster we create (by providing
 * the resource ID) and for any user that has IAM authentication enabled.  We will 
 * create a developer user with the appropriate grants for development activity that
 * will use IAM authentication.
 */
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "rds_iam_authentication_policy" {
  name        = "${var.env}-rds-iam-authentication"
  path        = "/"
  description = "Connect to the database cluster using IAM authentication"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
             "rds-db:connect"
         ],
         "Resource": [
             "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.platform_rds_cluster.cluster_resource_id}/*"
         ]
      }
   ]
}
EOF
}

/*
 * Retrieve groups we've set up earlier in the IAM module and attach the RDS IAM auth
 * policy to the groups.
 */
data "aws_iam_group" "dev_iam_group" {
  group_name = "${var.env}-dev"
}

resource "aws_iam_group_policy_attachment" "dev_group_policy_attachment" {
  group      = data.aws_iam_group.dev_iam_group.group_name
  policy_arn = aws_iam_policy.rds_iam_authentication_policy.arn
}

data "aws_iam_group" "dev_admin_group" {
  group_name = "${var.env}-dev-admin"
}

resource "aws_iam_group_policy_attachment" "dev_admin_group_policy_attachment" {
  group      = data.aws_iam_group.dev_admin_group.group_name
  policy_arn = aws_iam_policy.rds_iam_authentication_policy.arn
}