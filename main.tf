# 1. Create the Main VPC
resource "aws_vpc" "fintech_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "fintech-enterprise-vpc"
    Environment = "Production"
  }
}

# 2. Create the Internet Gateway (Free Front Door)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fintech_vpc.id

  tags = {
    Name = "fintech-igw"
  }
}

# 3. Create a Public Subnet (For web servers/load balancers)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.fintech_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "fintech-public-1a"
  }
}

# 4. Create an Isolated Private Subnet (The Vault for databases)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "fintech-private-1a"
  }
}

# 5. Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fintech_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "fintech-public-rt"
  }
}

# 6. Associate the Public Subnet with the Public Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. Private Route Table (No NAT Gateway, strictly internal)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.fintech_vpc.id
  tags = { Name = "fintech-private-rt" }
}

# 8. Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# 9. Gateway VPC Endpoint for S3 (Free, private backbone tunnel)
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.fintech_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]
}

# 10. Lambda Security Group (Egress only on port 443 for HTTPS)
resource "aws_security_group" "lambda_sg" {
  name        = "fintech_lambda_sg"
  description = "Allow HTTPS outbound to S3"
  vpc_id      = aws_vpc.fintech_vpc.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}