provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet_ids" "ecs_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Type = "private"
    Kubernetes  = 1
  }
}

data "aws_subnet" "ecs_subnet_id" {
  for_each = data.aws_subnet_ids.ecs_subnet_ids.ids
  id       = each.value
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "platform-ecs-tasks"
  description = "Allow inbound access from the ALB only"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name        = "platform-ecs-tasks"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "ecs_tasks_sgr" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.lb_sg.id
  security_group_id        = aws_security_group.ecs_tasks_sg.id
}

resource "aws_security_group_rule" "egress_sgr" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_tasks_sg.id
}

resource "aws_ecs_cluster" "platform_ecs_cluster" {
  name = "platform-ecs"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app-task"
  task_role_arn            = aws_iam_role.ecs_task_role.arn           # role needed to make calls to other AWS services
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # role ECS container agent and docker can assume
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = templatefile("./app.json.tmpl", 
                                {
                                    app_image      = var.app_image,
                                    app_port       = var.app_port,
                                    fargate_cpu    = var.fargate_cpu,
                                    fargate_memory = var.fargate_memory,
                                    aws_region     = var.region
                                })
}

resource "aws_ecs_service" "platform_ecs_service" {
  name            = "platform-ecs-service"
  cluster         = aws_ecs_cluster.platform_ecs_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    subnets          = [for s in data.aws_subnet.ecs_subnet_id : s.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.platform_ecs_lb_tg.id
    container_name   = "app"
    container_port   = var.app_port
  }

  lifecycle { // these are updated per deployment, terraform shouldn't set them back to original
      ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role]
}