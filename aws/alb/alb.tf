//TODO: health checks on 8080
// add ingress for 80 and 443
// add ingress on docker instance from LB (or network)
// add egress on LB to docker
// variables

# Error: error deleting S3 Bucket (platform-lb-bucket): BucketNotEmpty: The bucket you tried to delete is not empty
#        status code: 409, request id: 743E934804A20FDB, host id: QfKxUnNkGJn2R2+2uHBac4l9o90QBpDGplTwKsz5OoOHx05oi9C5ArwshbBnRs+vn6qJWP84TU4=
#

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
  bucket = "platform-lb-bucket"
  acl    = "private"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alb_account}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::platform-lb-bucket/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::platform-lb-bucket/*",
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
      "Resource": "arn:aws:s3:::platform-lb-bucket"
    }
  ]
}
EOF

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

/* 
 * Create the load balancer. 
 */
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

/* 
 * Create a target group.  This is where we define groups where listeners will forward traffice
 * based on their rules.  This is also where health checks are specified.
 * https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html
 */
resource "aws_lb_target_group" "platform_lb_tg" {
  name     = "platform-lb"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id
}

/* 
 * Attach the target group to an instance or autoscaling group.  We'll connect this one to our 
 * docker instance
 */

data "aws_instance" "docker" {
  instance_tags = {
    Name        = "platform-docker"
  }
}

resource "aws_alb_target_group_attachment" "docker_tga" {
  target_group_arn = aws_lb_target_group.platform_lb_tg.arn
  target_id        = data.aws_instance.docker.id
  port             = 8080
}

/* 
 * Create the self-signed TLS certificate and move it to the AWS Certificate Manager.  You could do 
 * this manually as well.  If you have a production certificate you would upload it to the ACM
 * and then look it up by name and apply it here.  The client-vpn module has an example of looking
 * up a cert.
 */
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

/*
 * Listeners to listing on 80 and 443
 */
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