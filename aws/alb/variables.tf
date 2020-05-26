variable "region" {}
variable "env" {}

/*
 * This is the Elastic Load Balancing Account ID for the region (us-east-2).  Update
 * it for your region
 */
variable "alb_account" {
  default = "033677994240"
}

# Variables for app subnets, to which we'll allow egress
variable cidr_block_subnet_pri_1 {
}

variable cidr_block_subnet_pri_2 {
}

# To silence TF warnings
variable "key_pair_name" {
}
variable cidr_block_vpc {
}
variable cidr_block_subnet_pub_1 {
}
variable cidr_block_subnet_pub_2 {
}
variable cidr_block_subnet_rds_1 {
}
variable cidr_block_subnet_rds_2 {
}
variable cidr_block_subnet_vpn_1 {
}

