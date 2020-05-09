# Error: Failure configuring LB attributes: InvalidConfigurationRequest: Access Denied for bucket: platform-lb-bucket. Please check S3bucket permission
#        status code: 400, request id: a1a46d88-9a17-4493-ad60-c6463c66ec9e

provider "aws" {
  region = var.region
}

provider "tls" {}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

/*
 * Find the subnets ids that are tagged public, map these to subnets, and then
 * iterate through those subnet ids to build a group that can later be used on
 * instance creation
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

// for logs
resource "aws_s3_bucket" "lb_s3_bucket" {
  bucket = "platform-lb-bucket"
  acl    = "private"
  
  tags = {
    Name        = "platform-lb-bucket"
    Environment = var.env
  }
}

#TODO: update
resource "aws_security_group" "lb_sg" {

  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-lb"
  description = "HTTPS from world"

  tags = {
    Name        = "platform-lb"
    Environment = var.env
  }
}

resource "aws_lb" "platform_lb" {
  name               = "platform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for s in data.aws_subnet.public_subnet_id : s.id]

  access_logs {
    bucket  = aws_s3_bucket.lb_s3_bucket.bucket
    prefix  = "platform-lb"
    enabled = true
  }

  tags = {
    Environment = var.env
  }
}

resource "aws_lb_target_group" "platform_lb_tg" {
  name     = "platform-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "dev.internal"
    organization = "Developers, Inc"
  }

  validity_period_hours = 72

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.private_key.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem
}

resource "aws_lb_listener" "lb_listener_https" {
  load_balancer_arn = aws_lb.platform_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.platform_lb_tg.arn
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

output "lb_dns_name" {
    value = aws_lb.platform_lb.dns_name
}