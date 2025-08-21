variable "web_server_port" {
  description = "TCP Port number for Apache2"
  type        = number
  default     = 8080
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "web_server_subnet"
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "app_server_subnet"
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "db_server_subnet"
  }
}

resource "aws_internet_gateway" "inet_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gw"
  }
}
resource "aws_route_table" "vpc_main_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inet_gw.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.vpc_main_route_table.id
}
resource "aws_security_group" "web_access" {
  name        = "web-ingress-sg"
  description = "Allow inbound web traffic to TCP/8080"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Allow inbound web traffic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_icmp" {
  security_group_id = aws_security_group.web_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_ingress_web_traffic" {
  security_group_id = aws_security_group.web_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_server_port
  to_port           = var.web_server_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh" {
  security_group_id = aws_security_group.web_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_out" {
  security_group_id = aws_security_group.web_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "-1"
  to_port           = "-1"
  ip_protocol       = "-1"
}

resource "aws_instance" "awslab" {
  ami                         = "ami-001e387a55c961ff2"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.web_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_access.id]
  associate_public_ip_address = true
  key_name                    = "cobeank_pub_key"
  tags = {
    Name = "web-server1"
  }

  depends_on = [aws_internet_gateway.inet_gw]


  user_data = <<-EOF
    #!/bin/bash -x
    apt update
    apt install apache2
    echo "<VirtualHost *:${var.web_server_port}>" | tee /etc/apache2/sites-available/000-default.conf
    echo "ServerAdmin webmaster@localhost" | tee -a /etc/apache2/sites-available/000-default.conf
    echo "DocumentRoot /var/www/html" | tee -a /etc/apache2/sites-available/000-default.conf 
    echo "</VirtualHost>" | tee -a /etc/apache2/sites-available/000-default.conf
    echo "Listen ${var.web_server_port}" | tee /etc/apache2/ports.conf
    echo "<IfModule ssl_module>" | tee -a /etc/apache2/ports.conf
    echo "Listen 443" | tee -a /etc/apache2/ports.conf
    echo "</IfModule>" | tee -a /etc/apache2/ports.conf
    echo "<IfModule mod_gnutls.c>" | tee -a /etc/apache2/ports.conf
    echo " Listen 443" | tee -a /etc/apache2/ports.conf
    echo "</IfModule>" | tee -a /etc/apache2/ports.conf
    echo "Hello, World, It's Kelly" | tee /var/www/html/index.html
    echo "And this was also Terraform" | tee -a /var/www/html/index.html
    systemctl restart apache2
    
    EOF

  user_data_replace_on_change = true
}
output "web_server_public_ip" {
  value       = aws_instance.awslab.public_ip
  description = "web server1 public IP"
}

output "web_server_private_ip" {
  value       = aws_instance.awslab.private_ip
  description = "web server subnet IP address"
}

output "aws_web_server_subnet" {
  value       = aws_subnet.web_subnet.cidr_block
  description = "The subnet for web servers"
}

output "security_group" {
  value = aws_security_group.web_access.vpc_id
}
