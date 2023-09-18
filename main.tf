resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
   tags = {
    Name = "${var.project_name}-${var.project_env}-vpc",
    Project = var.project_name,
    Env = var.project_env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.project_env}-igw",
    Project = var.project_name,
    Env = var.project_env
  }
}


resource "aws_subnet" "public" {
  count = 3
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.cidr_block, 3, count.index)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.project_env}-public${count.index + 1}",
    Project = var.project_name,
    Env = var.project_env
  }
}

resource "aws_subnet" "private" {
  count = 3
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.cidr_block, 3, "${count.index + 3}")
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.project_env}-private${count.index + 1}",
    Project = var.project_name,
    Env = var.project_env
  }

}


resource "aws_eip" "eip" {
  domain   = "vpc"

    tags = {
    Name = "${var.project_name}-${var.project_env}-eip",
    Project = var.project_name,
    Env = var.project_env
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[1].id

    tags = {
    Name = "${var.project_name}-${var.project_env}-nat-gw",
    Project = var.project_name,
    Env = var.project_env
  }

  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-public",
    Project = var.project_name,
    Env = var.project_env
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-private",
    Project = var.project_name,
    Env = var.project_env
  }
}


resource "aws_route_table_association" "public" {
  count = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}



resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.project_env}-bastion"
  description = "Allow only SSH port from my ip"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "SSH port"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-bastion",
    Project = var.project_name,
    Env = var.project_env
  }
}



resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-${var.project_env}-frontend"
  description = "Allow only HTTP & HTTPS port from my all"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTP port"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS port"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-frontend",
    Project = var.project_name,
    Env = var.project_env
  }
}


resource "aws_security_group" "backend" {
  name        = "${var.project_name}-${var.project_env}-backend"
  description = "Allow only 3306 port from my ip"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "MySQL port"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [ aws_security_group.frontend.id ]
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-backend",
    Project = var.project_name,
    Env = var.project_env
  }
}
