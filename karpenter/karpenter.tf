module "karpenter_iam" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.4.0"

  cluster_name                    = local.cluster_name
  queue_name                      = join("-", ["karpenter", local.cluster_name, local.region])
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = join("-", ["karpenter-node-role", local.cluster_name, local.region])
  create_pod_identity_association = true
  iam_role_name                   = join("-", ["karpenter-controller", local.cluster_name, local.region])
  create_iam_role                 = true
  iam_role_use_name_prefix        = false
  namespace                       = local.service_accounts.karpenter_controller.namespace
  service_account                 = local.service_accounts.karpenter_controller.name
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  tags = local.tags

  depends_on = [module.eks]
}

module "karpenter" {
  source = "./modules/k8s-karpenter"

  karpenter_provider_values_tpl  = "${path.module}/src/helm/karpenter-provider-helm-values-tpl.yml"
  karpenter_resources_values_tpl = "${path.module}/src/helm/karpenter-resources-helm-values-tpl.yml"
  karpenter_provider_parameters = {
    controller_image_tag                         = "v1.8.2"
    controller_image_digest                      = "sha256:ec27ec5b66f313d89174e3d59eee766caff99a746f36f74f156fd186b5baf407"
    replicas                                     = 1
    serviceAccount_create                        = true
    serviceAccount_name                          = local.service_accounts.karpenter_controller.name
    karpenter_settings_aws_clusterEndpoint       = module.eks.cluster_endpoint
    karpenter_settings_aws_interruptionQueueName = module.karpenter_iam.queue_name
    karpenter_settings_aws_clusterName           = local.cluster_name
    karpenter_node_role_name                     = module.karpenter_iam.node_iam_role_name
    serviceAccount_annotations = indent(4, yamlencode({
      "eks.amazonaws.com/role-arn" = module.karpenter_iam.node_iam_role_arn
    }))
    nodeSelector = indent(2, yamlencode({
      "kubernetes.io/os" = "linux"
    }))
    topologySpreadConstraints = indent(2, yamlencode([
      {
        labelSelector = {
          matchLabels = {
            "app.kubernetes.io/instance" = "karpenter"
            "app.kubernetes.io/name"     = "karpenter"
          }
        }
        maxSkew           = 1
        topologyKey       = "topology.kubernetes.io/zone"
        whenUnsatisfiable = "ScheduleAnyway"
      }
    ]))
  }
}
