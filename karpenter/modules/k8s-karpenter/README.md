# Karpenter K8s Module

This Terraform module deploys K8s resources for Karpenter.

## Usage

```hcl
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

```

```bash
terraform init
terraform apply
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.83.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.13.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.31.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.13.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.31.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.karpenter_crd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_resources](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.karpenter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create a dedicated namespace for Karpenter. | `bool` | `true` | no |
| <a name="input_karpenter_namespace"></a> [karpenter\_namespace](#input\_karpenter\_namespace) | The Kubernetes namespace in which Karpenter will be deployed. | `string` | `"karpenter"` | no |
| <a name="input_karpenter_provider_parameters"></a> [karpenter\_provider\_parameters](#input\_karpenter\_provider\_parameters) | Karpenter provider parameters | <pre>object({<br>    controller_image_tag                         = string<br>    controller_image_digest                      = string<br>    replicas                                     = number<br>    serviceAccount_create                        = bool<br>    serviceAccount_name                          = string<br>    karpenter_settings_aws_clusterEndpoint       = string<br>    karpenter_settings_aws_clusterName           = string<br>    karpenter_settings_aws_interruptionQueueName = string<br>    karpenter_node_role_name                     = string<br>    serviceAccount_annotations                   = string<br>    nodeSelector                                 = string<br>    affinity                                     = string<br>    topologySpreadConstraints                    = string<br>  })</pre> | n/a | yes |
| <a name="input_karpenter_provider_values_tpl"></a> [karpenter\_provider\_values\_tpl](#input\_karpenter\_provider\_values\_tpl) | Helm values template file path for chart Karpenter-provider | `string` | n/a | yes |
| <a name="input_karpenter_resources_values_tpl"></a> [karpenter\_resources\_values\_tpl](#input\_karpenter\_resources\_values\_tpl) | Helm values template file path for chart Karpenter-resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_karpenter_namespace"></a> [karpenter\_namespace](#output\_karpenter\_namespace) | n/a |
