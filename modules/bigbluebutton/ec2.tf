# --- ec2.tf ---
# 
#Author:    Jason Paul 

# Create EC2 instance for hosting BigBlueButton

resource "aws_instance" "ec2_bigbluebutton" {
  ami                         = var.ami_id
  instance_type               = var.ec2_instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.bigbluebutton-security-group.id]
  key_name                    = aws_key_pair.bigbluebutton-ssh.key_name

  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-ec2"
  }
  user_data = file("${path.module}/userdata.sh")
}

# Create EBS volume for storing all BigBlueButton data.  Using 1TB to allow for enough storage for recordings.

resource "aws_ebs_volume" "ebs_bigbluebutton" {
  availability_zone = var.aws_availability_zone
  size              = 1000
  encrypted         = true
  tags = {
    Name = "${var.namespace}-${var.environment}-bbb-ebs"
  }
}

# Attach EBS volume to EC2 instance - Must start after /dev/sdf
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html

resource "aws_volume_attachment" "bigbluebutton_disk" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ebs_bigbluebutton.id
  instance_id = aws_instance.ec2_bigbluebutton.id
}

# Add SSH Public Key for CLI Access

resource "aws_key_pair" "bigbluebutton-ssh" {
  key_name   = "bigbluebutton-public-ssh"
  public_key = var.ssh_public_key
}