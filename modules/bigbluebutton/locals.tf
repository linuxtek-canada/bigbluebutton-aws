locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  # Minimal cloud-init to prepare instance for Ansible
  cloud_init_config = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true

    packages:
      - python3
      - python3-pip
      - python3-apt
      - haveged
      - awscli
      - curl
      - wget
      - net-tools
      - jq

    runcmd:
      - systemctl enable --now haveged

    write_files:
      - path: /etc/cloud/cloud-init-done
        content: "done"

    final_message: "Cloud-init complete. Instance ready for Ansible."
  EOF
}
