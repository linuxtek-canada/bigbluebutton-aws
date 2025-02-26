# --- vpc.tf ---
# 
#Author:    Jason Paul 

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-vpc"
  }
}

# Create Internet Gateway and Attach it to VPC

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-internet-gateway"
  }
}

# Create Route Table and Add Public Route

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-public-route-table"
  }
}

# Create Public Subnet 1

resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.aws_availability_zone
  cidr_block              = var.public_subnet_1
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-public-subnet"
  }
}

# Create Private Subnet 1

resource "aws_subnet" "private-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_1
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-private-subnet"
  }
}

# Associate Public Subnet 1 to "Public Route Table"

resource "aws_route_table_association" "public-subnet-1-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

# Create Security Group to allow required traffic
# https://github.com/bigbluebutton/bbb-install?tab=readme-ov-file#configuring-the-external-firewall

resource "aws_security_group" "bigbluebutton-security-group" {
  name        = "${var.namespace}-${var.environment}-bbb-security-group"
  description = "Security Group - BigBlueButton TCP/UDP Ports"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_access" {
  security_group_id = aws_security_group.bigbluebutton-security-group.id
  description       = "Allow SSH Access"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = join(", ", var.ssh_location) #Convert list of IP blocks into string for rule
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_access" {
  security_group_id = aws_security_group.bigbluebutton-security-group.id
  description       = "Allow HTTP Access"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_access" {
  security_group_id = aws_security_group.bigbluebutton-security-group.id
  description       = "Allow HTTPS Access"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}


resource "aws_vpc_security_group_ingress_rule" "allow_rtp_access" {
  security_group_id = aws_security_group.bigbluebutton-security-group.id
  description       = "Allow FreeSwitch/HTML5 Client RTP Stream Access"
  from_port         = 16384
  to_port           = 32768
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_traffic" {
  security_group_id = aws_security_group.bigbluebutton-security-group.id
  description       = "Allow Outbound Traffic"  
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}