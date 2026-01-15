locals {
  tags = {
    Environment = "demo"
  }
  region   = "us-east-1"
  azs      = 3
  vpc_cidr = "10.0.0.0/16"
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]
  cluster_name       = "eks-cluster"
  kubernetes_version = "1.34"
  pod_identities = {
    aws_ebs_csi = {
      name                      = "aws-ebs-csi"
      attach_aws_ebs_csi_policy = true
      use_name_prefix           = false
    }
  }
}

data "aws_availability_zones" "available" {
  state  = "available"
  region = local.region
}
