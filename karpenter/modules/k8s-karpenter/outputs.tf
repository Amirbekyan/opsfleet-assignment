output "karpenter_namespace" {
  value = kubernetes_namespace.karpenter[0].metadata[0].name
}
