# 1. The Trust Policy: Who is allowed to wear this hat?
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 2. The Role: The actual "hat" being created
resource "aws_iam_role" "fintech_lambda_role" {
  name               = "fintech_temporary_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

# 3. The Permissions: What are they allowed to do while wearing the hat?
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.fintech_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4. Mandatory permissions for Lambda to run inside a VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.fintech_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# 5. S3 Vault Access Policy (Strictly scoped to our bucket)
resource "aws_iam_policy" "s3_vault_access" {
  name        = "fintech_s3_vault_access"
  description = "Allow Lambda to interact with the S3 document vault"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject", "s3:GetObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.fintech_document_vault.arn}/*"
      }
    ]
  })
}

# 6. Attach the S3 Policy to the Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.fintech_lambda_role.name
  policy_arn = aws_iam_policy.s3_vault_access.arn
}