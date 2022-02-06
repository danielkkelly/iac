/*
 * Basic role and policy attachment.  Same as generic SSM policy but this policy will be
 * assigned to HA monitoring instances and is allowed to assume the roles configured 
 * above for reassigning the VIP.  We could simply allow the typical SSM policy to assume
 * the role above but that would allow all instances to monitor and reassign VIPs and 
 * we only want that for HA instances so hence some redundancy.
 */ 
 resource "aws_iam_role" "ec2_ha_role" {
  name = "platform-${var.env}-ec2-ha-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_trust_ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_ha_role_ssm_policy_attachment" {
  role       = aws_iam_role.ec2_ha_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ec2_ha_profile" {
  role = aws_iam_role.ec2_ha_role.name
  name = "platform-${var.env}-ec2-ha-profile"
}