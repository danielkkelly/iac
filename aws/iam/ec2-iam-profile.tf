/*
 * We add the environment in the naming of roles, etc.  This is not strictly necessary if
 * you use separate credentials for all of your environments.  However, if you choose to
 * run all of your environments on one account then this makes that a bit easier.
 *
 * The following resources are related to system manager, which patches machines on a 
 * given maintenance schedule. 
 */
data "aws_iam_policy_document" "assume_role_trust_ec2_policy" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}
 
resource "aws_iam_role" "ec2_role" {
  name = "platform-${var.env}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_trust_ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_role_ssm_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  role = aws_iam_role.ec2_role.name
  name = "platform-${var.env}-ec2-profile"
}