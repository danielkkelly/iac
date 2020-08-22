/* 
 * Create a target group.  This is where we define groups where listeners will forward traffice
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

data "aws_instance" "docker" {
  instance_tags = {
    Name = "platform-docker"
  }
}

resource "aws_alb_target_group_attachment" "docker_tga" {
  target_group_arn = aws_lb_target_group.platform_docker_lb_tg.arn
  target_id        = data.aws_instance.docker.id
  port             = 8080
}

resource "aws_lb_listener_rule" "docker_listener_rule" {
  listener_arn = aws_lb_listener.lb_listener_https.arn
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
 */
data "aws_security_group" "docker_sg" {
  tags = {
    Name = "platform-docker"
  }
}

// Update the docker server to allow ingress
resource "aws_security_group_rule" "lb_http_sgr" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_sg.id
  security_group_id        = data.aws_security_group.docker_sg.id
}