/*
 * Allow an HA instance monitor to get the details about an instance and to reassign a 
 * VIP associated with the instance to another instance if it determins that the monitored
 * instance is down.
 */
resource "aws_iam_policy" "ha_monitor_policy" {
  name   = "${var.env}-ha-monitor-policy"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Action": [
            "ec2:AssignPrivateIpAddresses",
            "ec2:DescribeInstances"
        ],
        "Effect": "Allow",
        "Resource": "*"
    }
}
EOF
}

resource "aws_iam_role" "ec2_ha_monitor_role" {
  name = "platform-${var.env}-ha-monitor-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"AWS": "${aws_iam_role.ec2_ha_role.arn}"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ha_monitor_assume_role_policy_attachment" {
  role       = aws_iam_role.ec2_ha_monitor_role.name
  policy_arn = aws_iam_policy.ha_monitor_policy.arn
}