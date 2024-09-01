#!/bin/bash

# Docker version type (default to 'latest' if not provided)
DOCKER_VERSION=${1:-"latest"}

# Function to install dependencies required for OS detection
install_detection_dependencies() {
    sudo apt-get update
    sudo apt-get install -y lsb-release gnupg curl
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if Docker is already installed and running
if command_exists docker && sudo systemctl is-active --quiet docker; then
    echo "Docker is already installed and running. Skipping Docker installation."
    DOCKER_INSTALLED=true
else
    DOCKER_INSTALLED=false
fi

# Check if Docker Compose is already installed
if command_exists docker-compose; then
    echo "Docker Compose is already installed. Skipping Docker Compose installation."
    COMPOSE_INSTALLED=true
else
    COMPOSE_INSTALLED=false
fi

# If both Docker and Docker Compose are installed, exit
if [ "$DOCKER_INSTALLED" = true ] && [ "$COMPOSE_INSTALLED" = true ]; then
    echo "Both Docker and Docker Compose are already installed. Nothing to do."
    exit 0
fi

# Detect if the system is Debian or Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
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

if [ "$DOCKER_INSTALLED" = false ]; then
    # Update package index and install prerequisites
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key (force overwrite if it exists)
    curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | sudo tee /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null

    # Add Docker's official repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_NAME $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index again with Docker repo
    sudo apt-get update

    # Install Docker based on the specified version
    if [ "$DOCKER_VERSION" = "latest" ]; then
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        sudo apt-get install -y docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    # Verify Docker installation
    if sudo systemctl status docker --no-pager; then
        echo "Docker has been installed and started successfully."
    else
        echo "Failed to start Docker service. Please check the installation logs and try again."
        exit 1
    fi
else
    echo "Skipping Docker installation as it's already installed."
fi

if [ "$COMPOSE_INSTALLED" = false ]; then
    # Install Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Verify Docker Compose installation
    docker-compose --version

    echo "Docker Compose has been installed successfully."
else
    echo "Skipping Docker Compose installation as it's already installed."
fi

echo "Installation process completed."