module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.4.0"

  name                                   = local.cluster_name
  kubernetes_version                     = local.kubernetes_version
  endpoint_public_access                 = true
  enabled_log_types                      = ["audit", "api", "authenticator"]
  create_cloudwatch_log_group            = false
  cloudwatch_log_group_retention_in_days = 3
  authentication_mode                    = "API"
  addons = {
    aws-ebs-csi-driver = {
      most_recent = true
      pod_identity_association = [
        {
          role_arn        = module.pod_identity["aws_ebs_csi"].iam_role_arn
          service_account = local.service_accounts.aws_ebs_csi.name
        }
      ]
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent                 = true
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets
  cluster_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  eks_managed_node_groups = {
    default_node_group = {
      name            = "default-node-group"
      use_name_prefix = false
      subnet_ids      = module.vpc.private_subnets
      instance_types  = ["t3.xlarge", "t3a.xlarge"]
      capacity_type   = "ON_DEMAND"

      min_size     = 1
      max_size     = 5
      desired_size = 1

      ami_type          = "AL2023_x86_64_STANDARD"
      disk_size         = 50
      ebs_optimized     = true
      enable_monitoring = true

      update_config = {
        max_unavailable_percentage = 33
      }

      launch_template_tags = {
        "k8s.io/cluster-autoscaler/enabled"               = true
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
      }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEFSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonFSxFullAccess                = "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
        AmazonEKSVPCResourceController     = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      }
    }
  }
  security_group_additional_rules = {
    vpc_https = {
      description = "VPC CIDR to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  enable_cluster_creator_admin_permissions = true

}
