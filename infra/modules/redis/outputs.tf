output "endpoint" {
  description = "Host del nodo de Redis."
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "port" {
  description = "Puerto de Redis."
  value       = aws_elasticache_cluster.this.cache_nodes[0].port
}

output "cluster_id" {
  description = "Identificador del clúster de ElastiCache."
  value       = aws_elasticache_cluster.this.cluster_id
}
