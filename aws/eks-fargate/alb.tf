data "aws_lb" "platform_lb" {
  name = "platform-lb"
}

data "aws_lb_listener" "lb_listener_https" {
  load_balancer_arn = data.aws_lb.platform_lb.arn
  port              = 443
}

/* 
 * Create a target group.  This is where we define groups where listeners will forward traffic
 * based on their rules.  This is also where health checks are specified.
 * https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html
 */
resource "aws_lb_target_group" "platform_pod_lb_tg" {
  name     = "platform-pod"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id
}