output "ecr_registry_id" {
  value = aws_ecr_repository.platform_ecr.registry_id
}

output "ecr_repository_name" {
  value = aws_ecr_repository.platform_ecr.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.platform_ecr.repository_url
}