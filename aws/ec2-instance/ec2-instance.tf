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
    volume_size = var.volume_size
    encrypted = true

    tags = {
      Backup = "1"
    }
  }

  lifecycle { /* avoid repacing the instance when a later AMI is available */
     ignore_changes = [ami]
  }

  tags = {
    Name          = "platform-${var.host_type}"
    HostType      = var.host_type
    Environment   = var.env
    "Patch Group" = var.env
    Backup        = "1"
  }
}