#!/bin/bash

# Docker version type (default to 'latest' if not provided)
DOCKER_VERSION=${1:-"latest"}

# Function to install dependencies required for OS detection
install_detection_dependencies() {
    sudo apt-get update
    sudo apt-get install -y lsb-release gnupg curl apt-transport-https ca-certificates software-properties-common
}

# Function to add Docker's GPG key and repository
add_docker_repo() {
    curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Use the correct codename based on the OS
    if [[ "$OS_NAME" == "ubuntu" ]]; then
        # Ubuntu's codenames are derived directly
        CODENAME=$(lsb_release -cs)
        # If using Ubuntu 24.04 (noble), fallback to jammy for Docker repository
        if [[ "$CODENAME" == "noble" ]]; then
            CODENAME="jammy"
        fi
    elif [[ "$OS_NAME" == "debian" ]]; then
        # Debian 12 is codenamed "bookworm"
        CODENAME="bookworm"
    fi

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_NAME $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
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

# If Docker is already installed, exit
if [ "$DOCKER_INSTALLED" = true ]; then
    echo "Docker is already installed. Nothing to do."
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
    # Add Docker's official GPG key and repository
    add_docker_repo

    # Update package index and install Docker
    sudo apt-get update

    # Install Docker based on the specified version
    if [ "$DOCKER_VERSION" = "latest" ]; then
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    else
        sudo apt-get install -y docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io docker-buildx-plugin
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

echo "Docker installation process completed."