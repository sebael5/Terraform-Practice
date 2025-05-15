provider "aws" {
  region = "us-west-2"  # Cambia la región según tus necesidades
}

# Crear VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Crear una subred pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Crear una subred privada
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"
  tags = {
    Name = "private-subnet"
  }
}

# Crear una gateway de Internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Crear una tabla de ruteo para la subred pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Asociar la subred pública con la tabla de ruteo
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Crear un Security Group básico para EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Crear una instancia EC2 (para Kubernetes o pruebas)
resource "aws_instance" "k8s_node" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Cambia esto por una AMI válida (Ubuntu, Amazon Linux, etc.)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  security_group         = aws_security_group.ec2_sg.id
  associate_public_ip_address = true

  tags = {
    Name = "k8s-node"
  }
}

# Crear un Elastic IP (opcional)
resource "aws_eip" "k8s_eip" {
  instance = aws_instance.k8s_node.id
}

# Output: Dirección IP pública de la instancia EC2
output "instance_public_ip" {
  value = aws_instance.k8s_node.public_ip
}

