provider "aws" {
  region  = var.region
  profile = var.env
}

resource "aws_ecr_repository" "platform_ecr" {
  name                 = "platform"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
      Environment = var.env
  }
}

/* 
 * We'll keep tagged images indefinitely and untagged images get purged after a 
 * few weeks
 */
resource "aws_ecr_lifecycle_policy" "platform_ecr_policy" {
  repository = aws_ecr_repository.platform_ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 7 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 7
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}