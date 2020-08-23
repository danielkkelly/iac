data "aws_lb" "platform_lb" {
  name = "platform-lb"
}

data "aws_lb_listener" "lb_listener_https" {
  load_balancer_arn = data.aws_lb.platform_lb.arn
  port              = 443
}

resource "aws_lb_target_group" "platform_ecs_lb_tg" {
  name        = "platform-ecs"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"
}

resource "aws_lb_listener_rule" "ecs_listener_rule" {
  listener_arn = data.aws_lb_listener.lb_listener_https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.platform_ecs_lb_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

/*
 * Security group for authorization to ECS instances
 */
data "aws_security_group" "lb_sg" {
    name = "platform-lb"
}