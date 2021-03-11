resource "aws_sns_topic_subscription" "subscription" {
  count     = length(var.subscriptions)
  topic_arn = var.topic_arn
  protocol  = var.subscriptions[count.index].protocol
  endpoint  = var.subscriptions[count.index].endpoint
}