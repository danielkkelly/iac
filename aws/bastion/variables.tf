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