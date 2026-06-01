#------------------------------------------------------------------------------
# Security Group for BigBlueButton
#------------------------------------------------------------------------------
resource "aws_security_group" "bbb" {
  name        = "${local.name_prefix}-bbb-sg"
  description = "Security group for BigBlueButton instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-bbb-sg"
  }
}

#------------------------------------------------------------------------------
# Ingress Rules
#------------------------------------------------------------------------------

# SSH access (restricted)
resource "aws_security_group_rule" "ssh" {
  count             = length(var.allowed_ssh_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.bbb.id
  description       = "SSH access from allowed CIDRs"
}

# HTTP (for Let's Encrypt verification and redirect)
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_web_cidrs
  security_group_id = aws_security_group.bbb.id
  description       = "HTTP access for web and LetsEncrypt"
}

# HTTPS (main web interface)
resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_web_cidrs
  security_group_id = aws_security_group.bbb.id
  description       = "HTTPS access for BigBlueButton web interface"
}

# TURN/TLS (for users behind restrictive firewalls)
resource "aws_security_group_rule" "turn_tls" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "udp"
  cidr_blocks       = var.allowed_web_cidrs
  security_group_id = aws_security_group.bbb.id
  description       = "TURN over UDP 443 for firewall traversal"
}

# FreeSWITCH WebRTC media (UDP range for audio/video)
resource "aws_security_group_rule" "freeswitch_media" {
  type              = "ingress"
  from_port         = 16384
  to_port           = 32768
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bbb.id
  description       = "FreeSWITCH WebRTC media UDP ports"
}

#------------------------------------------------------------------------------
# Egress Rules
#------------------------------------------------------------------------------

# Allow all outbound traffic
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bbb.id
  description       = "Allow all outbound traffic"
}
