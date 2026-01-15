variable "create_namespace" {
  description = "Whether to create a dedicated namespace for Karpenter."
  type        = bool
  default     = true
}

variable "karpenter_namespace" {
  description = "The Kubernetes namespace in which Karpenter will be deployed."
  type        = string
  default     = "karpenter"
}

variable "karpenter_provider_parameters" {
  description = "Karpenter provider parameters"
  type = object({
    controller_image_tag                         = string
    controller_image_digest                      = string
    replicas                                     = number
    serviceAccount_create                        = bool
    serviceAccount_name                          = string
    karpenter_settings_aws_clusterEndpoint       = string
    karpenter_settings_aws_clusterName           = string
    karpenter_settings_aws_interruptionQueueName = string
    karpenter_node_role_name                     = string
    serviceAccount_annotations                   = string
    nodeSelector                                 = string
    topologySpreadConstraints                    = string
  })
}

variable "karpenter_resources_values_tpl" {
  description = "Helm values template file path for chart Karpenter-resources"
  type        = string
}

variable "karpenter_provider_values_tpl" {
  description = "Helm values template file path for chart Karpenter-provider"
  type        = string
}
