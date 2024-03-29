#
# Environment
#
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

#
# Host
#
variable "instance_type" {
  default = "t2.xlarge"
}

variable "volume_size" {
  default = 30
}

#
# Network
#
variable "ingress_ports" {
  type    = list(any)
  default = ["22", "8080", "8443", "9990"]
}

variable "host_number" {
  default = "40"
}

variable "alb_target_port" {
  description = "The container port that will serve up your application"
  default = 8080
}

# Variables that help allow private network access to the RDS server
variable "cidr_block_subnet_vpn_1" {}

# To silence TF warnings
variable "cidr_block_vpc" {}
variable "cidr_block_subnet_pub_1" {}
variable "cidr_block_subnet_pub_2" {}
variable "cidr_block_subnet_pri_1" {}
variable "cidr_block_subnet_pri_2" {}
variable "cidr_block_subnet_rds_1" {}
variable "cidr_block_subnet_rds_2" {}
