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

