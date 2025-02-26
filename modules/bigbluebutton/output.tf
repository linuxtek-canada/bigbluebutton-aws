output "public_ip" {
  value = aws_instance.ec2_bigbluebutton.public_ip
}

output "private_ip" {
  value = aws_instance.ec2_bigbluebutton.private_ip
}