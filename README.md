## 🛠️ System Architecture & Component Layers

### 1. Network Layer (VPC Topology & Routing)
* **Region:** N. Virginia (`us-east-1`)
* **Design:** Segmented architecture dividing traffic at the subnet boundary.
* **Public Subnet:** Attached to an Internet Gateway for managed external ingress/egress.
* **Private Subnet (Secure Enclave):** Completely isolated from direct internet routing.
* **Internal Routing:** Utilizes a custom Private Route Table connected to a Gateway VPC Endpoint (`com.amazonaws.us-east-1.s3`), ensuring all storage traffic remains entirely on the private AWS backbone, bypassing the public internet without the cost overhead of a NAT Gateway.

### 2. Identity & Access Layer (IAM & STS Trust)
* **Framework:** Principle of Least Privilege (PoLP).
* **Implementation:** Deployed an IAM Role with an explicit trust policy allowing the AWS Lambda service to assume it via the Security Token Service (`sts:AssumeRole`).
* **Permissions:** Restricted strictly to VPC execution access (`AWSLambdaVPCAccessExecutionRole`) and a custom, customer-managed policy explicitly scoped only to the ARN of the specific S3 vault.

### 3. Storage Layer (Secure S3 Document Vault)
* **Resource:** Amazon S3 with an isolated, dynamically generated global namespace.
* **Data-at-Rest Protection:** Mandatory Server-Side Encryption utilizing the `AES256` cryptographic standard.
* **Boundary Security:** Explicit `aws_s3_bucket_public_access_block` configuration applied, physically preventing public ACLs or bucket policies from exposing assets.

### 4. Compute Layer (Serverless Execution)
* **Runtime:** Python 3.12 managed environment.
* **Network Placement:** Physically deployed *inside* the Private Subnet, protected by a strict egress-only Security Group restricted to Port 443 (HTTPS).
* **Deployment Workflow:** Automated compilation via Terraform's `archive_file` provider, zipping local source code (`processor.py`) and calculating cryptographic hashes to ensure deployment integrity.