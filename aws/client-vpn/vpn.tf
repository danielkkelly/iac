# Generate a CA and associated server and client public and private keys.  To do follow
# https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/authentication-authorization.html#mutual
# The outputs get uploaded to the AWS ACM.  After this is done you'll have two ACM certs and
# these are referenced below as "server" and "client1.domain.tld" (keeping with the AWS example).

# After the certificates are squared away you'll run terraform to build out the endpoint and add
# network associations.  This script will find all of your private subnets and add them.

# There is additional configuration required on the client after all of this is set up. See 
# https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html for details.
# You need to download the open VPN configuration, modify it, and import it on your client.  
# You also need to have an Open VPN client installed.  Try https://openvpn.net/.

provider "aws" {
  region = var.region
}

data "aws_acm_certificate" "server" {
  domain   = "server"
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "client" {
  domain   = "client1.domain.tld"
  statuses = ["ISSUED"]
}

resource "aws_cloudwatch_log_group" "vpn_log_group" {
  name = "platform-vpn-group"
  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_stream" "vpn_log_stream" {
  name           = "platform-vpn-stream"
  log_group_name = aws_cloudwatch_log_group.vpn_log_group.name
}

resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = "platform-vpn-endpoint"
  client_cidr_block      = "10.60.0.0/22"
  server_certificate_arn = data.aws_acm_certificate.server.arn
  split_tunnel           = true # consider disabling for added security

  dns_servers = [cidrhost(data.aws_vpc.vpc.cidr_block, 2)]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = data.aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_log_group.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_log_stream.name
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet_ids" "pri_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    VPN  = "1"
    Type = "private"
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnet_assoc" {
  for_each               = data.aws_subnet_ids.pri_subnet_ids.ids
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = each.value
}

/*
 * After the resources are created, we need to add ingress for the VPN.  This isn't 
 * yet available as a feature of terraform.  You could use a local provisioner
 * and null resource to do this automatically but I haven't had time to set that
 * up.
 * https://github.com/terraform-providers/terraform-provider-aws/issues/7494
 */
resource "null_resource" "client_vpn_ingress" {
  triggers = {
    vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  }

  provisioner "local-exec" {
    command = <<EOC
          aws ec2 authorize-client-vpn-ingress \
                    --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.vpn_endpoint.id} \
                    --target-network-cidr ${data.aws_vpc.vpc.cidr_block} \
                    --authorize-all-groups
    EOC
  }
}

output vpn_endpoint_id {
  value = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
}