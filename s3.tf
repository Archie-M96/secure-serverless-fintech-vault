# 1. Create the Secure S3 Bucket
resource "aws_s3_bucket" "fintech_document_vault" {
  bucket_prefix = "fintech-vault-" # AWS requires globally unique names, this adds random numbers to the end
  
  tags = {
    Name        = "Fintech Document Vault"
    Environment = "Production"
  }
}

# 2. Block ALL Public Access (The ultimate safety net)
resource "aws_s3_bucket_public_access_block" "vault_lockdown" {
  bucket = aws_s3_bucket.fintech_document_vault.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# 3. Enforce Server-Side Encryption (Data protected at rest)
resource "aws_s3_bucket_server_side_encryption_configuration" "vault_encryption" {
  bucket = aws_s3_bucket.fintech_document_vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}