## AWS EKS cluster setup with Karpenter

### Summary
This Terraform module provisions a production-ready Amazon EKS cluster using the AWS CLI default profile.  It deploys the following components:
 * A dedicated VPC with public and private subnets, Internet and NAT Gateways
 * An Amazon EKS cluster (latest available version: 1.34)
 * EKS Pod Identity for workload authentication
 * Karpenter for dynamic node provisioning and autoscaling

### Usage
> [!IMPORTANT]
> Ensure the following tools are installed and properly configured with sufficient permissions in the target AWS account:
> * `git`
> * `terraform` (or `tofu`)
> * `awscli`
> * `kubectl`

> [!NOTE]
> The Terraform configuration uses the default AWS CLI profile.

Clone this repo and run:
```bash
git clone git@github.com:Amirbekyan/opsfleet-assignment.git
cd opsfleet-assignment/karpenter

terraform init
terraform apply
```

Once the apply completes successfully, the EKS cluster and Karpenter will be fully operational.  The following Karpenter `NodePool` resources are preconfigured and will automatically provision nodes when requested by the Kubernetes Scheduler:
| NodePool | Description |
|---|---|
| general-x86 | General-purpose x86_64 (Intel/AMD) on-demand instances |
| spot-x86 | General-purpose x86_64 Spot instances |
| general-arm | General-purpose arm64 AWS Graviton instances |

### Running Workloads on Specific Architectures

Sample Kubernetes manifests are proviced under [examples](./src/examples).

Configure access to the cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name eks-cluster
```
Deploy a workload targeting Graviton (arm64) nodes:
```bash
kubectl apply -f ./src/examples/deployment-arm.yml
```
The deployment uses Kubernetes node selectors to ensure the pod is scheduled onto an arm64-backed node provisioned by Karpenter.