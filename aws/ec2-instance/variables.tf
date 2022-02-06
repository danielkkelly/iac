variable "env" {}
variable "key_pair_name" {}

variable "instance_type" {
  description = "This is the type of EC2 instance (e.g. t2.nano)"
}

variable "volume_size" {
  default = 30
}

variable "host_type" {
  description = "The type of host machine by function (e.g. bastion)"
}

variable "private_ip" {}

variable "secondary_private_ips" {
  type = list(string)
  default = []
}

variable "subnet_id" {
  type = string
}

variable "vpc_security_group_ids" {
  type        = list(any)
  description = "This is a list of security group IDs"
}

variable "instance_profile_name" {
  description = "Allows setting the IAM role for the EC2 instance"
  type = string
  default = null
}