#Definición del proveedor de nube y región
provider "aws" {
  region = var.aws_region
}

#Creación de la VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "VPC-Portfolio-Pao"
  }
}

#Creación de la subred pública
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true #Hace que la web sea accesible
    tags = {
      Name = "Subnet-publica"
    }
}

#Creación del IGW
resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.main_vpc.id
}

#Creación de la tabla de ruteo para el tráfico de salida
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public-rt.id
}

#Creación del security group
resource "aws_security_group" "web_sg" {
  name = "web-server-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Creación de la instancia EC2
resource "aws_instance" "web_server" {
 ami = var.ami_id
 instance_type = var.instance_type
 subnet_id = aws_subnet.public_subnet.id
 vpc_security_group_ids = [aws_security_group.web_sg.id]

    #Instalación de Apache al iniciarse
    user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello, this server was deployed with Terraform.</h1>" > /var/www/html/index.html
    EOF

    tags = {
      name = "servidor-web-portfolio"
    }
}