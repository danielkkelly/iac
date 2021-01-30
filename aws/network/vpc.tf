resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "platform-vpc"
    Type        = "platform-vpc"
    Environment = var.env
  }
}

# TODO: filter
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_iam_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_log_group.arn
  traffic_type    = "REJECT"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_log_group" {
  name = "platform-vpc-flow-log"
}

resource "aws_iam_role" "vpc_flow_log_iam_role" {
  name = "platform-vpc-flow-log"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_flow_log_iam_role_policy" {
  name = "example"
  role = aws_iam_role.vpc_flow_log_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}