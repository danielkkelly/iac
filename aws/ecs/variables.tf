#
# Environment
#
variable "region" {}
variable "env" {}
variable "key_pair_name" {}

#
# ECS
# 
variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default = "ecs-task-execution-role"
}

variable "ecs_auto_scale_role_name" {
  description = "ECS auto scale role Name"
  default = "myEcsAutoScaleRole"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}

#
# App
#
variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "platform:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 8080
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "health_check_path" {
  default = "/"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "2048"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "8192"
}