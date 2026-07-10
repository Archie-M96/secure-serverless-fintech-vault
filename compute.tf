# 1. Zip the Python file automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "processor.py"
  output_path = "processor.zip"
}

# 2. Deploy the Serverless Function (Upgraded for VPC)
resource "aws_lambda_function" "fintech_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "FintechDocumentProcessor"
  role             = aws_iam_role.fintech_lambda_role.arn
  handler          = "processor.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"

  # Physically placing Lambda inside the Private Subnet
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Wait for VPC permissions before creating
  depends_on = [aws_iam_role_policy_attachment.lambda_vpc_access]

  tags = {
    Environment = "Production"
  }
}