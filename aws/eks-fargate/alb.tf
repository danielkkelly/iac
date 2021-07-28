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
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_listener_rule" "pod_listener_rule" {
  listener_arn = data.aws_lb_listener.lb_listener_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.platform_pod_lb_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

/* 
 * Security group updates to allow the load balancer access to the instances
 */
data "aws_security_group" "lb_sg" {
  tags = {
    Name = "platform-lb"
  }
}

resource "aws_security_group_rule" "lb_http_sgr" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.lb_sg.id
  security_group_id        = module.eks.cluster_primary_security_group_id
}