output "cluster-role-arn" {
  description = "Cluster Role ARN"
  value = aws_eks_cluster.eks-cluster.role_arn
}
output "node-role-arn" {
  description = "Node Role ARN"
  value = aws_eks_node_group.eks-node-group.node_role_arn
}
output "cluster_endpoint" {
  description = "Cluster Endpoint"
  value = aws_eks_cluster.eks-cluster.endpoint
}
output "cluster_name" {
  description = "Cluster name"
  value = aws_eks_cluster.eks-cluster.name
}