#!/bin/bash

# Docker version type (default to 'latest' if not provided)
DOCKER_VERSION=${1:-"latest"}

# Function to install dependencies required for OS detection
install_detection_dependencies() {
    sudo apt-get update
    sudo apt-get install -y lsb-release gnupg
}

# Check if Docker is already installed and running
if command -v docker &> /dev/null && sudo systemctl is-active --quiet docker; then
    echo "Docker is already installed and running. Skipping installation."
    exit 0
fi

# Detect if the system is Debian or Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
else
    echo "Cannot detect the OS. Please run this script on Debian or Ubuntu."
    exit 1
fi

# Check if the OS is either Ubuntu or Debian
if [[ "$OS_NAME" != "ubuntu" && "$OS_NAME" != "debian" ]]; then
    echo "This script only supports Debian or Ubuntu. Detected OS: $OS_NAME"
    exit 1
fi

# Install OS detection dependencies
install_detection_dependencies

# Update package index and install prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker’s official GPG key (force overwrite if it exists)
curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | sudo tee /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null

# Add Docker’s official repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_NAME $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again with Docker repo
sudo apt-get update

# Install Docker based on the specified version
if [ "$DOCKER_VERSION" = "latest" ]; then
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
else
    sudo apt-get install -y docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io
fi

# Verify Docker installation
sudo systemctl status docker --no-pager
