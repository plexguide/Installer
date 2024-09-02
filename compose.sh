#!/bin/bash

# ANSI color codes for formatting
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"  # No color

# Function to install Docker Compose
install_docker_compose() {
    # Fetch the latest Docker Compose version from GitHub
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Download and install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Verify Docker Compose installation
    if docker-compose --version; then
        echo -e "${GREEN}Docker Compose has been installed successfully.${NC}"
    else
        echo -e "${RED}Docker Compose installation failed. Please check the installation steps and try again.${NC}"
        exit 1
    fi
}

# Detect if the system is Debian or Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
else
    echo -e "${RED}Cannot detect the OS. Please run this script on Debian or Ubuntu.${NC}"
    exit 1
fi

# Check if the OS is either Ubuntu 20.04, 22.04, 24.04, or Debian
if [[ "$OS_NAME" == "ubuntu" && ( "$OS_VERSION" == "20.04" || "$OS_VERSION" == "22.04" || "$OS_VERSION" == "24.04" ) ]] || [[ "$OS_NAME" == "debian" ]]; then
    echo -e "${GREEN}Detected OS: $OS_NAME $OS_VERSION. Proceeding with Docker Compose installation...${NC}"
    install_docker_compose
else
    echo -e "${RED}This script only supports Ubuntu 20.04, 22.04, 24.04, and Debian. Detected OS: $OS_NAME $OS_VERSION.${NC}"
    exit 1
fi

echo -e "${GREEN}Installation process completed.${NC}"