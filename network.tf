provider "aws" {
  region  = var.aws_region
  profile = "YOUR_AWS_PROFILE"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_names = data.aws_availability_zones.available.names
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"


  tags = {
    Name = var.vpc_tag_name
  }
}


# Create subnets for each availability zone using for_each
resource "aws_subnet" "public" {
  for_each = toset(local.az_names)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, index(local.az_names, each.key))
  availability_zone = each.key

  tags = {
    terraform = true
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

}

resource "aws_route_table_association" "main" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "lb_security_group" {
  name        = var.lb_security_group_name
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = var.lb_security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_sg_inbound_rule_allow_https_ipv4" {
  security_group_id = aws_security_group.lb_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "lb_sg_outbound_rule_allow_https_ipv4" {
  security_group_id = aws_security_group.lb_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lb_sg_outbound_rule_allow_http_ipv4_from_ec2_sg" {
  security_group_id            = aws_security_group.lb_security_group.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2_security_group.id
}

resource "aws_security_group" "ec2_security_group" {
  name        = var.eb_security_group_name
  description = "Security group for ec2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = var.eb_security_group_name
  }
}


resource "aws_vpc_security_group_ingress_rule" "inbound_rule_allow_http_ipv4_from_load_balancer" {
  security_group_id            = aws_security_group.ec2_security_group.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lb_security_group.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound_rule_allow_all_traffic" {
  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}


resource "aws_security_group" "rds_security_group" {
  name        = var.rds_security_group_name
  description = "Security group for rds database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = var.rds_security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg_inbound_rule" {
  security_group_id            = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.ec2_security_group.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}


resource "aws_vpc_security_group_egress_rule" "rds_sg_outbound_rule" {
  security_group_id            = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.ec2_security_group.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
























