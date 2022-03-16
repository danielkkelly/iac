output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster on 1.14 or later. Referred to as 'Cluster security group' in the EKS console."
  value       = module.eks.cluster_primary_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = var.eks_cluster_name
}

output "aws_lbc_role_arn" {
  description = "AWS Load Balancer Controller Role ARN"
  value       = aws_iam_role.lbc_iam_role.arn
}

output "platform_target_group_arn" {
  description = "Used to set up the load balancer target group and the platform pod"
  value       = aws_lb_target_group.platform_pod_lb_tg.arn
}