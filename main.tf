resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw_main"
  }
}

resource "aws_subnet" "pbsubnet-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = var.az1a
  map_public_ip_on_launch = "true"

  tags = {
    Name = "PBSubnet_1"
  }
}

resource "aws_subnet" "pbsubnet-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = var.az1b
  map_public_ip_on_launch = "true"

  tags = {
    Name = "PBSubnet_2"
  }
}

resource "aws_subnet" "prsubnet-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet3_cidr
  availability_zone       = var.az1a
  map_public_ip_on_launch = "false"

  tags = {
    Name = "PRSubnet_1"
  }
}

resource "aws_subnet" "prsubnet-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet4_cidr
  availability_zone       = var.az1b
  map_public_ip_on_launch = "false"

  tags = {
    Name = "PRSubnet_2"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "pub-RT"
  }
}

resource "aws_route_table" "example1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "pr-RT"
  }
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.prsubnet-1.id
  route_table_id = aws_route_table.example1.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.prsubnet-2.id
  route_table_id = aws_route_table.example1.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pbsubnet-1.id
  route_table_id = aws_route_table.example.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pbsubnet-2.id
  route_table_id = aws_route_table.example.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  count                       = 2
  ami                         = "ami-099b3d23e336c2e83"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  availability_zone           = var.az1a
  key_name                    = "ssh-key"
  subnet_id                   = aws_subnet.pbsubnet-1.id
  security_groups             = [aws_security_group.allow_tls.id]
  user_data                   = file("apache.sh")

  tags = {
    Name = "Server-${count.index + 1}"
  }
}