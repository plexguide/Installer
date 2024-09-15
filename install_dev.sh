#!/bin/bash

# Path to the configuration file
CONFIG_FILE="/pg/config/config.cfg"

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Function to create directories with the correct permissions
create_directories() {
    echo "Creating necessary directories..."

    # Define directories to create
    directories=(
        "/pg/config"
        "/pg/scripts"
        "/pg/apps"
        "/pg/stage"
        "/pg/installer"
    )

    # Loop through the directories and create them with the correct permissions
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo "Created $dir"
        else
            echo "$dir already exists"
        fi
        # Set ownership to user with UID and GID 1000
        chown -R 1000:1000 "$dir"
        # Set the directories as executable
        chmod -R +x "$dir"
    done
}

# Function to download and place files into /pg/stage/
download_repository() {
    echo "Preparing /pg/stage/ directory..."

    # Ensure /pg/stage/ is completely empty, including hidden files
    if [[ -d "/pg/stage/" ]]; then
        rm -rf /pg/stage/*
        rm -rf /pg/stage/.* 2>/dev/null || true
        echo "Cleared /pg/stage/ directory."
    fi

    # Download the repository from the dev branch
    echo "Downloading PlexGuide repository from the dev branch..."
    git clone -b dev "https://github.com/plexguide/PlexGuide.com.git" /pg/stage/

    # Verify download success
    if [[ $? -eq 0 ]]; then
        echo "Repository successfully downloaded to /pg/stage/."
    else
        echo "Failed to download the repository. Please check your network connection."
        exit 1
    fi
}

# Function to move scripts from /pg/stage/mods/scripts to /pg/scripts/
move_scripts() {
    echo "Moving scripts from /pg/stage/mods/scripts to /pg/scripts/..."

    # Check if the source directory exists
    if [[ -d "/pg/stage/mods/scripts" ]]; then
        mv /pg/stage/mods/scripts/* /pg/scripts/

        # Verify move success
        if [[ $? -eq 0 ]]; then
            echo "Scripts successfully moved to /pg/scripts/."
        else
            echo "Failed to move scripts. Please check the file paths and permissions."
            exit 1
        fi
    else
        echo "Source directory /pg/stage/mods/scripts does not exist. No files to move."
        exit 1
    fi
}

# Function to set or update the VERSION in the config file
set_config_version() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Creating config file at $CONFIG_FILE"
        touch "$CONFIG_FILE"
    fi

    if grep -q "^VERSION=" "$CONFIG_FILE"; then
        sed -i 's/^VERSION=.*/VERSION="PG Dev"/' "$CONFIG_FILE"
    else
        echo 'VERSION="PG Dev"' >> "$CONFIG_FILE"
    fi

    echo "VERSION has been set to PG Dev in $CONFIG_FILE"
}

show_exit() {
    bash /pg/installer/menu_exit.sh
}

# New installation process
create_directories
download_repository
move_scripts
move_apps
check_and_install_docker
set_config_version

# Source the commands.sh script and run the create_command_symlinks function
source /pg/installer/commands.sh
create_command_symlinks

show_exit
