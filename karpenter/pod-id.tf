locals {
  service_accounts = {
    aws_ebs_csi = {
      namespace = "kube-system"
      name      = "ebs-csi-controller-sa"
    }
    karpenter_controller = {
      namespace = "karpenter"
      name      = "karpenter-controller-sa"
    }
  }
  normalized_service_accounts = {
    for name, sa in local.service_accounts :
    name => try(sa[*], [sa])
  }
}

module "pod_identity" {
  source          = "terraform-aws-modules/eks-pod-identity/aws"
  version         = "2.2.1"
  for_each        = local.pod_identities
  name            = "${each.value.name}-pod-identity"
  use_name_prefix = try(each.value.use_name_prefix, false)
  tags            = local.tags

  # EBS CSI
  attach_aws_ebs_csi_policy = try(each.value.attach_aws_ebs_csi_policy, false)
  aws_ebs_csi_kms_arns      = try(each.value.aws_ebs_csi_kms_arns, [])
}
