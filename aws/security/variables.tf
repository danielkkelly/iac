# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}
variable "replication_region" {}

# SMS
variable "sms_enabled" {
  default = false
}
variable "sms_number" {}