#!/bin/bash

# Docker version type (default to 'latest' if not provided)
DOCKER_VERSION=${1:-"latest"}

# Update package index and install prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker’s official repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

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
