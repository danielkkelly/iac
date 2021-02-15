provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

/*
 * Find the subnets ids that are tagged public, map these to subnets, and then iterate through 
 * those subnet ids to build a group that can later be used on instance creation. 
 */
data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Type = "public"
  }
}

data "aws_subnet" "public_subnet_id" {
  for_each = data.aws_subnet_ids.public_subnet_ids.ids
  id       = each.value
}

/* 
 * Create an S3 bucket for logs and attach the appropriate policy.  Note the variable for 
 * the region-specific load balancer account.  More inforomation available in the docs.
 * https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
 */
resource "aws_s3_bucket" "lb_s3_bucket" {
  bucket        = "platform-lb-bucket-${var.env}"
  force_destroy = true
  acl           = "private"
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alb_account[var.region]}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::platform-lb-bucket-${var.env}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::platform-lb-bucket-${var.env}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::platform-lb-bucket-${var.env}"
    },
    {
      "Sid": "Require SSL",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::platform-lb-bucket-${var.env}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "platform-lb-bucket"
    Environment = var.env
  }
}

/*
 * Find that NAT gateway for the VPC so that we can allow traffic from it through the load 
 * balancer.  Not strictly necessary but if you have an application that needs to hit the
 * LB to communicate with another application then this is useful.  We'll add an ingress rule
 * to the security group rule below.
 */
data "aws_nat_gateway" "ngw" {
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group" "lb_sg" {

  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-lb"
  description = "HTTPS from world"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_nat_gateway.ngw.public_ip}/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress
  }

  egress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = [var.cidr_block_subnet_pri_1,
    var.cidr_block_subnet_pri_2]
  }

  tags = {
    Name        = "platform-lb"
    Environment = var.env
  }
}

/* 
 * Create the load balancer. 
 */
resource "aws_lb" "platform_lb" {
  name               = "platform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for s in data.aws_subnet.public_subnet_id : s.id]

  drop_invalid_header_fields = true //security best practice

  access_logs {
    bucket  = aws_s3_bucket.lb_s3_bucket.bucket
    prefix  = "platform-lb"
    enabled = true
  }

  tags = {
    Environment = var.env
  }
}

/* 
 * Find the certificate in the ACM
 */
data "aws_acm_certificate" "cert" {
  domain   = "${var.env}.internal"
  statuses = ["ISSUED"]
}

/*
 * Listeners to listing on 80 and 443
 */
resource "aws_lb_listener" "lb_listener_https" {
  load_balancer_arn = aws_lb.platform_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

// redirect HTTP to HTTPS
resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn = aws_lb.platform_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

