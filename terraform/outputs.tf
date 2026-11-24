output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command that points kubectl at the new cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "ecr_repository_url" {
  description = "Push the Debugger Agent image here, then set newName in cluster/kustomization.yaml."
  value       = aws_ecr_repository.debugger_agent.repository_url
}

output "karpenter_node_role" {
  description = "Instance role name hardcoded in cluster/nodepool.yaml."
  value       = module.karpenter.node_iam_role_name
}

output "workload_subnet_id" {
  description = "The single subnet where system, monitoring, and GPU nodes run."
  value       = module.vpc.public_subnets[0]
}
