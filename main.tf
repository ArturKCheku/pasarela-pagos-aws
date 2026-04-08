provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "red_principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-Practicas-Cloud"
  }
}

# Subred Pública (Para el servidor VPN)
resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.red_principal.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"

  tags = {
    Name = "Subred-Publica-VPN"
  }
}

# Subred Privada (Para tu API de pagos)
resource "aws_subnet" "subred_privada" {
  vpc_id            = aws_vpc.red_principal.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "Subred-Privada-Backend"
  }
}

# Puerta de enlace a Internet
resource "aws_internet_gateway" "igw_principal" {
  vpc_id = aws_vpc.red_principal.id

  tags = {
    Name = "IGW-Proyecto-UPV"
  }
}

# Tabla de rutas y asociación
resource "aws_route_table" "tabla_publica" {
  vpc_id = aws_vpc.red_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_principal.id
  }

  tags = {
    Name = "Tabla-Rutas-Publica"
  }
}

resource "aws_route_table_association" "asociacion_publica" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_publica.id
}

# Firewall para VPN (Security Group)
resource "aws_security_group" "sg_vpn" {
  name        = "Permitir_VPN_SSH"
  description = "Permitir trafico de Wireguard y SSH"
  vpc_id      = aws_vpc.red_principal.id

  ingress {
    description = "Conexion Wireguard VPN"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Conexion SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "SG-Servidor-VPN"
  }
}

# Consulta de AMI y creación de Instancia
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Creación de par de claves SSH
resource "aws_key_pair" "clave_ssh_local" {
  key_name   = "clave-vpn-upv"
  public_key = file("~/.ssh/clave_vpn_upv.pub")
}

# Creación de instancia VPN
resource "aws_instance" "servidor_vpn" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.subred_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_vpn.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.clave_ssh_local.key_name

  tags = {
    Name = "Servidor-VPN-UPV"
  }
}

# Firewall para API(Security Group)
resource "aws_security_group" "sg_api" {
  name        = "Permitir_API_SSH"
  description = "Permitir trafico de API y SSH"
  vpc_id      = aws_vpc.red_principal.id

  ingress {
    description = "Conexion con FastAPI"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_vpn.id]
  }

  ingress {
    description = "Conexion SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_vpn.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Servidor-API"
  }
}

# Creación de instancia API
resource "aws_instance" "servidor_api" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.subred_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_api.id]
  associate_public_ip_address = false

  key_name = aws_key_pair.clave_ssh_local.key_name

  tags = {
    Name = "Servidor-API-UPV"
  }
}

#configuracion nat para que la instancia privada pueda acceder a internet
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subred_publica.id

  tags = {
    Name = "NAT-Gateway-Proy"
  }

  depends_on = [aws_internet_gateway.igw_principal]
}

#Tabla de rutas para la subred privada
resource "aws_route_table" "tabla_privada" {
  vpc_id = aws_vpc.red_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Tabla-Rutas-Privada"
  }
}

resource "aws_route_table_association" "asociacion_privada" {
  subnet_id      = aws_subnet.subred_privada.id
  route_table_id = aws_route_table.tabla_privada.id
}

# Output de IP pública del servidor VPN
output "ip_publica_vpn" {
  description = "IP pública del servidor para conectar por SSH"
  value       = aws_instance.servidor_vpn.public_ip
}

# Output de IP privada 
output "ip_privada_api" {
  description = "IP privada del servidor para conectar por SSH"
  value       = aws_instance.servidor_api.private_ip
}