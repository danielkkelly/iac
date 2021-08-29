variable "use_default_name" {
  default = true
}

variable "namespace" {
  description = "Prefix applied to all logs creating using this module"
  default     = "platform"
}

variable "region" {}

variable "env" {
  default = "dev"
}
variable "name" {
  description = "Name of the log group"
}

variable "retention_in_days" {
  description = "Number of days to retain the logs in the log group"
  default     = 365
}