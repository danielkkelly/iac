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

  /* Allow services running on subnets aassociated with the NAT gatway to make inbound 
   * requests through the load balancer.  This isn't strictly required and not always
   * efficient but it is convenient
   */
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_nat_gateway.ngw.public_ip}/32"]
  }

  ingress { # HTTP
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress
  }

  ingress { # HTTPS
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress
  }

  dynamic "egress" {
    for_each = var.egress_ports
    content {
      from_port = egress.value
      to_port   = egress.value
      protocol  = "tcp"
      cidr_blocks = [var.cidr_block_subnet_pri_1, var.cidr_block_subnet_pri_2]
    }
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

  enable_deletion_protection = var.alb_deletion_protection

  drop_invalid_header_fields = true //security best practice

  access_logs {
    bucket  = module.alb_s3_bucket.bucket
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