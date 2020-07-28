provider "aws" {
  region  = var.region
  profile = var.env
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

//TODO: aws_ecr_lifecycle_policy