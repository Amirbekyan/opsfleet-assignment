resource "kubernetes_namespace" "karpenter" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.karpenter_namespace
  }
}

resource "helm_release" "karpenter_crd" {
  name             = "karpenter-crd"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter-crd"
  version          = "1.8.3"
  create_namespace = false
  namespace        = null
  replace          = true
  wait             = true
}

resource "helm_release" "karpenter_provider" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.8.3"
  namespace        = kubernetes_namespace.karpenter[0].id
  create_namespace = false

  values = [
    templatefile(var.karpenter_provider_values_tpl, {
      controller_image_tag                         = var.karpenter_provider_parameters.controller_image_tag
      controller_image_digest                      = var.karpenter_provider_parameters.controller_image_digest
      replicas                                     = var.karpenter_provider_parameters.replicas
      serviceAccount_create                        = var.karpenter_provider_parameters.serviceAccount_create
      serviceAccount_name                          = var.karpenter_provider_parameters.serviceAccount_name
      karpenter_settings_aws_clusterEndpoint       = var.karpenter_provider_parameters.karpenter_settings_aws_clusterEndpoint
      karpenter_settings_aws_clusterName           = var.karpenter_provider_parameters.karpenter_settings_aws_clusterName
      karpenter_settings_aws_interruptionQueueName = var.karpenter_provider_parameters.karpenter_settings_aws_interruptionQueueName
      serviceAccount_annotations                   = var.karpenter_provider_parameters.serviceAccount_annotations
      nodeSelector                                 = var.karpenter_provider_parameters.nodeSelector
      topologySpreadConstraints                    = var.karpenter_provider_parameters.topologySpreadConstraints
      prometheus_enabled                           = true
      prometheus_labels = indent(4, yamlencode({
        release = "prometheus"
      }))
  })]

  depends_on = [helm_release.karpenter_crd]
}

resource "helm_release" "karpenter_resources" {
  name             = "karpenter-resources"
  chart            = "${path.module}/helm/karpenter-resources"
  namespace        = kubernetes_namespace.karpenter[0].id
  create_namespace = false
  replace          = false

  values = [
    templatefile(var.karpenter_resources_values_tpl, {
      cluster_name             = var.karpenter_provider_parameters.karpenter_settings_aws_clusterName
      karpenter_node_role_name = var.karpenter_provider_parameters.karpenter_node_role_name
  })]

  depends_on = [helm_release.karpenter_crd, helm_release.karpenter_provider]
}
