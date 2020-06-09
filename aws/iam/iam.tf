# We add the environment in the naming of roles, etc.  This is not strictly necessary if
# you use separate credentials for all of your environments.  However, if you choose to
# run all of your environments on one account then this makes that a bit easier.

provider "aws" {
  region  = var.region
  profile = var.env
}

# The following resources are related to system manager, which patches machines on a 
# given maintenance schedule.  

resource "aws_iam_role" "ec2_ssm_role" {
  name = "platform-${var.env}-ec2-ssm-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  role = aws_iam_role.ec2_ssm_role.name
  name = "platform-${var.env}-ec2-ssm-profile"
}

resource "aws_iam_role" "ssm_maintenance_window_role" {
  name = "platform-${var.env}-ssm-maintenance-window-role"

  assume_role_policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"",
         "Effect":"Allow",
         "Principal":{
            "Service":[
               "ec2.amazonaws.com",
               "ssm.amazonaws.com"
           ]
         },
         "Action":"sts:AssumeRole"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_maintenance_window_attach" {
  role       = aws_iam_role.ssm_maintenance_window_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

# The following resources create a policy and group acess for developers who have
# API access.  It also creates users with AWS access 

resource "aws_iam_policy" "dev_policy" {
  name        = "${var.env}-dev"
  path        = "/"
  description = "EC2, ECR, EKS permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ecr:*",
        "eks:ListClusters",
        "eks:DescribeCluster"
      ],
      "Effect": "Allow",
      "Resource": "*"
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

resource "aws_iam_group" "dev_admin_group" {
  name = "${var.env}-dev-admin"
}

resource "aws_iam_group_policy_attachment" "dev_admin_policy_attachment" {
  group      = aws_iam_group.dev_admin_group.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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

output "user_key_id" {
  value = [for access_key in aws_iam_access_key.user_access_key: {
     "user"   = access_key.user,
     "id"     = access_key.id,
     "secret" = access_key.encrypted_secret
  }]
}