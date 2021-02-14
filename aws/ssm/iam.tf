# We add the environment in the naming of roles, etc.  This is not strictly necessary if
# you use separate credentials for all of your environments.  However, if you choose to
# run all of your environments on one account then this makes that a bit easier.

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