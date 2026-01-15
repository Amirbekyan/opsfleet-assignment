## Architectural Design Document: Innovate Inc. Cloud Infrastructure

### Summary
This document outlines the cloud infrastructure design for Innovate Inc.'s web application.  The solution utilizes AWS as the cloud provider, leveraging Amazon EKS for managed Kubernetes to ensure scalability and portability.  The deployment pipeline follows a GitOps methodology using GitHub Actions and ArgoCD to ensure rapid, secure and reliable delivery.

### Diagram
This diagram illustrates the flow of traffic from the user to the application, the segregation of subnets for security and the GitOps pipeline connecting GitHub, ECR, and the EKS Cluster.

![diagram](./aws-arch.svg)

### Cloud Environment Structure
To adhere to the principle of least privilege we recommend a multi-account strategy using AWS Organizations.

Recommended Account Structure:
 * Root Account: Used strictly for billing, AWS SSO (Identity Center) user management and SCPs (Service Control Policies).  No resources run here.
 * Log Archive Account: Hosts CloudTrail and Config logs from all accounts.
 * Service Account: Hosts the ECR (Container Registry), Client VPN and potentially centralized tooling.
 * Production Account: The live environment.
 * Staging Account: A replica of production for testing.  Lower resources/costs.
 * Development Account: A similar environment simplified for flexibilty in debugging and cost efficiency.

### Network Design
The network is designed for high availability and security, spanning 3 Availability Zones (AZs) within the selected region.

VPC Architecture:
CIDR Block: 10.0.0.0/16 (Provides 65K+ IPs, ample room for growth).

Subnet Strategy (Per AZ):
 * Public Subnet: Host the Application Load Balancer (ALB) and NAT Gateways.  Direct internet access via Internet Gateway (IGW).
 * Private Subnet: Host EKS Worker Nodes.  No direct internet access, outbound traffic routes through NAT Gateways.
 * Intra Subnet: Host RDS databases.  Strictly isolated with no internet route.

Network Security:
 * Security Groups: Strictly defined firewall rules (e.g., RDS only accepts traffic on port 5432 from the EKS Worker Node Security Group).
 * NACLs: Stateless backup layer of security for subnet boundaries.
 * WAF (Web Application Firewall): Attached to the ALB to protect against SQL injection, XSS, and common bot attacks.

### Compute Platform
We will leverage Amazon Elastic Kubernetes Service (EKS) to manage the containerized applications.  In production and staging environments the single page front-end app will be hosted on S3 bucket and served via CloudFront.

Cluster Configuration:
Control Plane: Fully managed by AWS across multiple AZs.

Data Plane (Worker Nodes):
Managed Node Groups: Used to simplify patching and updating of nodes.

Scaling Strategy:
 * Cluster Autoscaler: Automatically adds/removes EC2 nodes based on pending pods.
 * Horizontal Pod Autoscaler (HPA): Scales the number of Flask/React pods based on CPU/Memory usage.

Ingress:
Kubernetes Gateway API will be used to manage ingress traffic.  AWS Load Balancer will route external traffic to an Nginx instance which will itself route requests to appropriate application pods within the cluster further on.

Containerization Strategy:
 * Image Building: Dockerfiles will be optimized (multi-stage builds) to keep images lightweight.
 * Registry: Amazon ECR (Elastic Container Registry) with image scanning enabled to detect vulnerabilities on push.

### Database Architecture
Amazon Aurora for PostgreSQL is the chosen managed database service.  Aurora brings high throughput, 99.999% multi-region availability and DSQL alongside with full PostgreSQL compatibility.

High Availability: Multi-AZ Deployment. AWS automatically provisions a primary DB and a synchronous standby replica in a different AZ. If the primary fails, AWS handles the failover automatically.

Auxiliary Access:
Developers connect to databases through Client VPN configured in Service Account.

Backup & Recovery:
 * Automated daily snapshots with a retention period of 30 days.
 * Point-in-Time Recovery (PITR) enabled for granular recovery (up to 5 minutes ago).

### CI/CD & Deployment Strategy
We will implement a GitOps workflow to decouple CI (Integration) from CD (Delivery).

CI (GitHub Actions):
 * Runs unit tests.
 * Builds the Docker image.
 * Pushes the image to Amazon ECR with a unique tag (e.g., commit SHA).
 * Updates the Kubernetes manifest repository (Helm Chart) with the new image tag.

CD (ArgoCD):
 * ArgoCD running inside EKS detects the change in the manifest repository and automatically syncs the cluster state to match the git state (pulling the new image from ECR).

> [!NOTE]
> Why this approach?
>
> Security: The CI system (GitHub) does not need access to the production cluster. The cluster pulls changes from inside.
>
> Auditability: Git history becomes the history of your infrastructure and application deployments.

### Cost Optimization
Spot Instances: Use Spot Instances for the EKS Node Groups running stateless services (frontend/backend) in development environment to save up to 70% on compute costs.

Savings Plans: Commit to Compute Savings Plans for baseline usage (like the Database) for a 1-3 year term.
