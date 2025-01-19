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
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow RDP access from anywhere (secure this in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "windows11-sg"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "windows11-key"
  public_key = file("~/.ssh/id_rsa.pub") # Replace with your public key path
}

resource "aws_instance" "windows11" {
  ami           = "ami-0d8f6eb4f641ef691" # Update to a Windows 11 AMI ID available in your region
  instance_type = "t2.medium" # Use a suitable instance type for Windows 11
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.windows11_sg.name]

  tags = {
    Name = "windows11-instance"
  }

  user_data = <<-EOF
              <powershell>
              # Enable RDP and other initial configurations
              Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
              Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
              </powershell>
              EOF
}
