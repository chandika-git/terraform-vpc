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

