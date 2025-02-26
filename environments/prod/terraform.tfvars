namespace = "kwlug"

environment = "prod"

aws_region = "ca-central-1"

aws_availability_zone = "ca-central-1a"

# Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
# Recommended: https://docs.bigbluebutton.org/administration/install/
ami_id = "ami-0a474b3a85d51a5e5"

# Using c5a.2xlarge as instance type, based on BigBlueButton recommended requirements:
# https://github.com/bigbluebutton/bbb-install?tab=readme-ov-file#server-choices
# https://docs.bigbluebutton.org/administration/install/#minimum-server-requirements
ec2_instance_type = "c5a.2xlarge"

# Pull SSH IP list from Github Actions Secrets
# ssh_location = ["0.0.0.0/0"]

# Pull SSH Public Key from Github Actions Secrets
# ssh_public_key = ""

