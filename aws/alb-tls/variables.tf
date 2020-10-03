variable "region" {}
variable "env" {}

variable "validity_period_hours" {
  default = "8760" // a year
}

# To silence TF warnings
variable "key_pair_name" {}