# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

# Network
variable "is_public" {
  description = "If true, places the bastion host on a public subnet and gives it an EIP"
  default     = false
}
variable "host_number" { # .10 on whatever network is designated
  default = "10"
}

/* 
 * Because we use SSM for ingress the ingress should come only from one of our 
 * not-routable networks.
 */
variable "cidr_blocks_ingress" {
  default = ["10.0.0.0/8"]
}