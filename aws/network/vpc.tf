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

/*
 * This removes the inbound and outbound rules from the default security group,
 * improving overall security in the process and conforming with CIS.4.3.  This
 * is a special resource, per Terraform.  Terraform doesn't create the security
 * group, it simply adopts it and ensures that the inbound and outbound rules 
 * conform to our configuration (no rules in this case).
 */
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

/* 
 * Create a VPC flow log.  Satisfies CIS.2.9.
 */
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_iam_role.arn
  log_destination = module.vpc_flow_log_lg.arn
  traffic_type    = "REJECT"
  vpc_id          = aws_vpc.vpc.id
}

module "vpc_flow_log_lg" {
  source = "../cloudwatch-log-group"
  region = var.region
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
  name               = "platform-${var.env}-vpc-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_iam_policy_document.json
}

resource "aws_iam_policy" "vpc_flow_log_iam_policy" {
  name   = "platform-${var.env}-vpc-flow-log-policy"
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

resource "aws_iam_role_policy_attachment" "vpc_flow_log_iam_role_policy_attachment" {
  role       = aws_iam_role.vpc_flow_log_iam_role.id
  policy_arn = aws_iam_policy.vpc_flow_log_iam_policy.arn
}