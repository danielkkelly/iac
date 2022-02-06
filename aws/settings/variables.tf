# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

variable "replication_region" {
  description = "Region into which we replicate backups, set globally via environment variable"
}

# SMS
variable "sms_enabled" {
  default = false
}