output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_managed_node_groups_iam_roles" {
  value = {
    for ng_name, ng in module.eks.eks_managed_node_groups : ng_name => ng.iam_role_arn
  }
}
