provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "platform_ecr" {
  name                 = "platform-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
      Environment = var.env
  }
}