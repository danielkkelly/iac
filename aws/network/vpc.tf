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

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_iam_role.arn
  log_destination = module.vpc_flow_log_lg.arn
  traffic_type    = "REJECT"
  vpc_id          = aws_vpc.vpc.id
}

module "vpc_flow_log_lg" {
  source = "../cloudwatch-log-group"
  env    = var.env
  name   = "vpc-flow-log"
}

data "aws_iam_policy_document" "vpc_flow_log_iam_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_log_iam_role" {
  name               = "platfomr-${var.env}-vpc-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_iam_policy_document.json
}

resource "aws_iam_role_policy" "vpc_flow_log_iam_role_policy" {
  name = "${var.env}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
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