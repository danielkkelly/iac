# Environment
variable "region" {}
variable "env" {}
variable "key_pair_name" {}
variable "iac_home" {}

# Users and groups
variable "users_groups" {
  default = {
    dan = ["dev"]
  }
}

# Networks
variable "networks" {
  description = "Source IP ranges for AWS API use"
  type        = string
  default     = "\"0.0.0.0/0\""
}

# SNS
variable "policy_name" {
  description = "Name of policy to publish to Group SMS topic."
  type        = string
  default     = "group-sms-publish"
}

variable "policy_path" {
  description = "Path of policy to publish to Group SMS topic"
  type        = string
  default     = "/"
}

variable "role_name" {
  description = "The IAM role that allows Amazon SNS to write logs for SMS deliveries in CloudWatch Logs."
  type        = string
  default     = "platform-sns-cloudwatch-logs"
}