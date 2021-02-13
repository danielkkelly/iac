output "rds_cluster_endpoint" {
  description = "The cluster read and writ endpoint"
  value       = aws_rds_cluster.platform_rds_cluster.endpoint
}

output "rds_cluster_endpoint_reader" {
  description = "The cluster reader endpoint"
  value       = aws_rds_cluster.platform_rds_cluster.reader_endpoint
}