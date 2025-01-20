provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "windows11-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a" # Change to a specific AZ in your region
  tags = {
    Name = "windows11-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "windows11-gateway"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "windows11-route-table"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "windows11_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all inbound traffic (insecure)
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all inbound traffic (insecure)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "windows11-sg"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "windows11-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7fPfB4M1J3RWRv/zGIPeIvdfLTYZ2lf9R2hcIoAAAAADAQAB" # Public key hardcoded (insecure)
}

resource "aws_instance" "windows11" {
  ami           = "ami-0d8f6eb4f641ef691" # Update to a Windows 11 AMI ID available in your region
  instance_type = "t2.micro" # Use a minimal instance type (potential performance issues)
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.windows11_sg.name]

  tags = {
    Name = "windows11-instance"
  }

  user_data = <<-EOF
              <powershell>
              # Disable Windows Firewall (insecure)
              Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
              </powershell>
              EOF
}
