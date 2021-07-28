output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster on 1.14 or later. Referred to as 'Cluster security group' in the EKS console."
  value       = module.eks.cluster_primary_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = var.eks_cluster_name
}

output "aws_lbc_role_arn" {
  description = "AWS Load Balancer Controller Role ARN"
  value       = aws_iam_role.lbc_iam_role.arn
}