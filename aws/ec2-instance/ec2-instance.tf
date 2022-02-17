module "default_ami" {
  source = "../ami"
}

locals {
  instance_profile_name = var.instance_profile_name == null ? "platform-${var.env}-ec2-profile" : var.instance_profile_name
  host_name             = var.host_name == null ? var.host_type : var.host_name
}

resource "aws_instance" "instance" {
  ami                    = module.default_ami.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  private_ip             = var.private_ip
  iam_instance_profile   = local.instance_profile_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = var.volume_size
    encrypted   = true

    tags = {
      Backup = "1"
    }
  }

  secondary_private_ips = var.secondary_private_ips

  lifecycle { /* avoid repacing the instance when a later AMI is available */
    ignore_changes = [ami]
  }

  tags = {
    Name          = "platform-${local.host_name}"
    HostType      = var.host_type
    Environment   = var.env
    "Patch Group" = var.env
    Backup        = "1"
  }
}