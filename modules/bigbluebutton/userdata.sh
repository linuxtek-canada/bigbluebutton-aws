#!/bin/bash

# Userdata script to run on EC2 instance for initial configuration.

# Configure Date/Time
sudo timedatectl set-timezone America/Toronto

# Install Docker Prerequisites
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y ca-certificates curl gnupg lsb-release vim software-properties-common

# Install Docker packages
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# BBB - Set Language
sudo apt-get install -y language-pack-en
sudo update-locale LANG=en_US.UTF-8
sudo systemctl set-environment LANG=en_US.UTF-8

# Allow Ports
sudo ufw allow 80
sudo ufw allow 443