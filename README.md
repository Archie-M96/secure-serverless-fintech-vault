# Enterprise-Grade Serverless Fintech Vault

## Why I Built This Project
I wanted to answer a real constraint financial institutions face: how do you build a secure 
document-processing pipeline without paying for infrastructure you don't strictly need? Every 
decision below — from subnet isolation to choosing a VPC Endpoint over a NAT Gateway — was made 
to keep sensitive data traffic off the public internet while staying cost-realistic.

## What I Built

### 1. Network Layer (VPC Topology & Routing)
- **Region:** `us-east-1`
- Segmented architecture splitting traffic at the subnet boundary: a public subnet attached to 
  an Internet Gateway for managed ingress/egress, and a fully isolated private subnet (the 
  "secure enclave") with no direct internet route.
- A custom private route table connects to a Gateway VPC Endpoint 
  (`com.amazonaws.us-east-1.s3`), keeping all storage traffic on the private AWS backbone — no 
  NAT Gateway cost overhead.

### 2. Identity & Access Layer (IAM & STS Trust)
- Principle of Least Privilege throughout.
- Deployed an IAM role with an explicit trust policy allowing the Lambda service to assume it via 
  `sts:AssumeRole`.
- Permissions restricted to `AWSLambdaVPCAccessExecutionRole` plus a customer-managed policy 
  scoped only to the exact ARN of the vault's S3 bucket — not `*`.

### 3. Storage Layer (Secure S3 Document Vault)
- S3 bucket with a dynamically generated, isolated global namespace.
- Mandatory server-side encryption (`AES256`) enforced at rest.
- Explicit `aws_s3_bucket_public_access_block` applied, physically blocking any public ACL or 
  bucket policy from exposing the data.

### 4. Compute Layer (Serverless Execution)
- Python 3.12 runtime, deployed inside the private subnet.
- Egress-only security group restricted to port 443 (HTTPS) — nothing else can leave.
- Deployment automated via Terraform's `archive_file` provider, which zips `processor.py` and 
  hashes it to guarantee deployment integrity.

## What I'd Do Next
This is a strong v1 of the security posture, but at true enterprise scale I'd add KMS 
customer-managed keys instead of SSE-S3 for stricter key-rotation control, Cognito with 
enforced MFA for user-facing access, and CloudTrail data events on the bucket so every object 
access is individually auditable.
