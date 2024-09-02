#!/bin/bash

# Define color codes for echoing messages
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Function to install Ansible on Ubuntu
install_ansible_ubuntu() {
    echo -e "${GREEN}Detected Ubuntu ${VERSION_ID}. Installing Ansible...${NC}"
    sudo apt update -y
    sudo apt install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt update -y
    sudo apt install -y ansible
}

# Function to install Ansible on Debian
install_ansible_debian() {
    echo -e "${GREEN}Detected Debian ${VERSION_ID}. Installing Ansible...${NC}"
    sudo apt update -y
    sudo apt install -y software-properties-common
    sudo apt install -y ansible
}

# Detect the OS and VERSION
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo -e "${RED}Cannot determine the operating system. Exiting...${NC}"
    exit 1
fi

# Check if the OS is Ubuntu or Debian and call the appropriate function
if [[ "$ID" == "ubuntu" && ( "$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04" ) ]]; then
    install_ansible_ubuntu
elif [[ "$ID" == "debian" && "$VERSION_ID" == "12" ]]; then
    install_ansible_debian
else
    echo -e "${RED}This script supports only Ubuntu 22.04, Ubuntu 24.04, and Debian 12. Exiting...${NC}"
    exit 1
fi

# Verify the installation
echo -e "${GREEN}Ansible installation complete. Verifying the installation...${NC}"
ansible --version

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Ansible has been installed successfully!${NC}"
else
    echo -e "${RED}Ansible installation failed. Please check the error messages above.${NC}"
fi