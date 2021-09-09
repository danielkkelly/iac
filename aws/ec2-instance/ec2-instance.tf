module "default_ami" {
  source = "../ami"
}

data "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "platform-${var.env}-ec2-ssm-profile"
}

resource "aws_instance" "instance" {
  ami                    = module.default_ami.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  private_ip             = var.private_ip
  iam_instance_profile   = data.aws_iam_instance_profile.ec2_ssm_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true

    tags = {
      Backup = "1"
    }
  }

  tags = {
    Name          = "platform-${var.host_type}"
    HostType      = var.host_type
    Environment   = var.env
    "Patch Group" = var.env
    Backup        = "1"
  }
}

data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

resource "aws_route53_record" "host_record" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "${var.host_type}.${data.aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [var.private_ip]
}