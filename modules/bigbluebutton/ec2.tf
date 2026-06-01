#------------------------------------------------------------------------------
# EC2 Instance for BigBlueButton
#------------------------------------------------------------------------------
resource "aws_instance" "bbb" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bbb.id]
  iam_instance_profile   = aws_iam_instance_profile.bbb_instance.name

  user_data                   = local.cloud_init_config
  user_data_replace_on_change = false

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${local.name_prefix}-root-volume"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring = true

  tags = {
    Name = "${local.name_prefix}-server"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

#------------------------------------------------------------------------------
# Ansible Provisioner
#------------------------------------------------------------------------------
resource "null_resource" "ansible_provisioner" {
  count = var.enable_provisioning ? 1 : 0

  triggers = {
    instance_id = aws_instance.bbb.id
    domain      = var.domain_name
    version     = var.bbb_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/../../ansible/inventory
      cat > ${path.module}/../../ansible/inventory/hosts <<EOF
[bigbluebutton]
${aws_eip.bbb.public_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3

[bigbluebutton:vars]
bbb_hostname=${var.domain_name != "" ? var.domain_name : aws_eip.bbb.public_ip}
bbb_email=${var.admin_email}
bbb_version=${var.bbb_version}
bbb_install_greenlight=${var.install_greenlight}
bbb_install_firewall=true
aws_region=${var.aws_region}
s3_recordings_bucket=${aws_s3_bucket.recordings.id}
enable_s3_recordings=true
bbb_recording_retention_days=${var.recording_retention_days}
bbb_admin_password=${var.bbb_admin_password}
EOF
    EOT
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instance to be reachable..."
      for i in $(seq 1 30); do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ${var.ssh_private_key_path} ubuntu@${aws_eip.bbb.public_ip} "cloud-init status --wait" 2>/dev/null; then
          break
        fi
        echo "Attempt $i/30 - waiting 10s..."
        sleep 10
      done
      echo "Instance ready. Running Ansible..."
      cd ${path.module}/../../ansible && \
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i inventory/hosts \
        --private-key ${var.ssh_private_key_path} \
        playbooks/site.yml
    EOT

    environment = {
      ANSIBLE_FORCE_COLOR = "true"
    }
  }

  depends_on = [
    aws_instance.bbb,
    aws_eip_association.bbb,
    aws_s3_bucket.recordings
  ]
}

#------------------------------------------------------------------------------
# Elastic IP for stable public address
#------------------------------------------------------------------------------
resource "aws_eip" "bbb" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip"
  }
}

resource "aws_eip_association" "bbb" {
  instance_id   = aws_instance.bbb.id
  allocation_id = aws_eip.bbb.id
}
