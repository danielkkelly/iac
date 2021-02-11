#TODO: create policy (naming?) and attach to the dev groups
# need to retrieve the dev groups...
# need to replace variables in Resource clause

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
             "arn:aws:rds-db:${var.region}:${aws_caller_identify.current.account_id}:dbuser:${aws_rds_cluster.platform_rds_cluster.cluster_resource_id}/db_user"
         ]
      }
   ]
}
EOF
}