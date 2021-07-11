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
resource "aws_lb_target_group" "platform_docker_lb_tg" {
  name     = "platform-docker"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id
}

/* 
 * Attach the target group to an instance or autoscaling group.  We'll connect this one to our 
 * docker instance
 */

resource "aws_alb_target_group_attachment" "docker_tga" {
  target_group_arn = aws_lb_target_group.platform_docker_lb_tg.arn
  target_id        = aws_instance.docker.id
  port             = 8080
}

resource "aws_lb_listener_rule" "docker_listener_rule" {
  listener_arn = data.aws_lb_listener.lb_listener_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.platform_docker_lb_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

/* 
 * Docker security group updates to allow the load balancer access to the instance
 * Update the docker server to allow ingress
 */
data "aws_security_group" "lb_sg" {
  tags = {
    Name = "platform-lb"
  }
}

resource "aws_security_group_rule" "lb_http_sgr" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.lb_sg.id
  security_group_id        = aws_security_group.docker_sg.id
}