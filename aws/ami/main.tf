data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = ["self", "amazon"] # AWS

  filter {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  } 

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }   
}

output "id" {
    value = data.aws_ami.latest_amazon_linux.id
}