variable "subscriptions" {
  description = "List of endpoints and protocols subscribe."
  type        = list(object({
      protocol = string
      endpoint = string
  }))
  default     = []
}

variable "topic_arn" {
    description = "SNS Topic ARN"
    type = string
}