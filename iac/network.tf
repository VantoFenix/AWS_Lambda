# 1. VPC Principal (CIDR 10.0.0.0/16 según el diagrama)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.nombre_proyecto}-vpc-${terraform.workspace}" }
}

# 2. Internet Gateway (La puerta a Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.nombre_proyecto}-igw-${terraform.workspace}" }
}

# 3. Subredes Públicas (AZ-a y AZ-b)
resource "aws_subnet" "pub_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "${var.nombre_proyecto}-pub-a-${terraform.workspace}" }
}

resource "aws_subnet" "pub_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "${var.nombre_proyecto}-pub-b-${terraform.workspace}" }
}

# 4. Subredes Privadas (AZ-a y AZ-b)
resource "aws_subnet" "priv_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "${var.nombre_proyecto}-priv-a-${terraform.workspace}" }
}

resource "aws_subnet" "priv_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "${var.nombre_proyecto}-priv-b-${terraform.workspace}" }
}

# 5. EIP y NAT Gateway (El control de costos)
resource "aws_eip" "nat_a" {
  domain = "vpc"
}

# Este NAT Gateway siempre se crea (en la subred pública A)
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.pub_a.id
  tags = { Name = "${var.nombre_proyecto}-nat-a-${terraform.workspace}" }
}

# TABLAS DE RUTAS
# Ruta Pública (Hacia el Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.nombre_proyecto}-public-rt-${terraform.workspace}" }
}

resource "aws_route_table_association" "pub_a_assoc" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_b_assoc" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Ruta Privada A (Hacia el NAT Gateway A)
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = { Name = "${var.nombre_proyecto}-priv-rt-a-${terraform.workspace}" }
}

resource "aws_route_table_association" "priv_a_assoc" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

# Ruta Privada B (La enviamos al NAT A para ahorrar en DEV)
resource "aws_route_table_association" "priv_b_assoc" {
  subnet_id      = aws_subnet.priv_b.id
  route_table_id = aws_route_table.private_rt_a.id
}