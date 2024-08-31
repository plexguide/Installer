#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
NC="\033[0m"  # No color

# Paths
CONFIG_FILE="/pg/config/config.cfg"

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

# Function to check and install Docker if not installed
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "\e[38;5;196mD\e[38;5;202mO\e[38;5;214mC\e[38;5;226mK\e[38;5;118mE\e[38;5;51mR \e[38;5;201mI\e[38;5;141mS \e[38;5;93mI\e[38;5;87mN\e[38;5;129mS\e[38;5;166mT\e[38;5;208mA\e[38;5;226mL\e[38;5;190mL\e[38;5;82mI\e[38;5;40mN\e[38;5;32mG\e[0m"
        sleep .5
        chmod +x /pg/installer/docker.sh
        bash /pg/installer/docker.sh
    fi
}

# Function to check and install unzip if not present (for Beta installations)
check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo "unzip not found. Installing unzip..."
        sudo apt-get update
        sudo apt-get install -y unzip
        echo "unzip has been installed."
    fi
}

# Function to download and place files into /pg/stage/ (Alpha Installation)
download_repository() {
    echo "Preparing /pg/stage/ directory..."

    # Ensure /pg/stage/ is completely empty, including hidden files
    if [[ -d "/pg/stage/" ]]; then
        rm -rf /pg/stage/*
        rm -rf /pg/stage/.* 2>/dev/null || true
        echo "Cleared /pg/stage/ directory."
    fi

    # Download the repository
    echo "Downloading PlexGuide repository..."
    git clone https://github.com/plexguide/PlexGuide.com.git /pg/stage/

    # Verify download success
    if [[ $? -eq 0 ]]; then
        echo "Repository successfully downloaded to /pg/stage/."
    else
        echo "Failed to download the repository. Please check your network connection."
        exit 1
    fi
}

# Function to fetch all releases for Beta installations
fetch_releases() {
    curl -s https://api.github.com/repos/plexguide/PlexGuide.com/releases | jq -r '.[].tag_name' | grep -E '^11\.[0-9]\.B[0-9]+' | sort -r | head -n 50
}

# Function to download and extract Beta release
download_and_extract_beta() {
    local selected_version="$1"
    local url="https://github.com/plexguide/PlexGuide.com/archive/refs/tags/${selected_version}.zip"
    
    echo "Downloading and extracting ${selected_version}..."
    curl -L -o /pg/stage/release.zip "$url"
    
    unzip -o /pg/stage/release.zip -d /pg/stage/
    local extracted_folder="/pg/stage/PlexGuide.com-${selected_version}"
    
    if [[ -d "$extracted_folder" ]]; then
        echo "Found extracted folder: $extracted_folder"
                
        # Clear the /pg/scripts/ directory before moving files
        echo "Clearing /pg/scripts/ directory..."
        rm -rf /pg/scripts/*
        
        # Move scripts to /pg/scripts
        if [[ -d "$extracted_folder/mods/scripts" ]]; then
            echo "Moving scripts to /pg/scripts"
            mv "$extracted_folder/mods/scripts/"* /pg/scripts/
            chown -R 1000:1000 /pg/scripts/
            chmod -R +x /pg/scripts/
        else
            echo "No scripts directory found in $extracted_folder"
        fi

        # Clear the /pg/stage directory after moving the files
        rm -rf /pg/stage/*
        echo "Cleared /pg/stage directory after moving files."
        
    else
        echo "Extracted folder $extracted_folder not found!"
    fi
    
    echo "Files for ${selected_version} have been processed."
}

# Function to update the version in the config file
update_config_version() {
    local version="$1"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Creating config file at $CONFIG_FILE"
        touch "$CONFIG_FILE"
    fi

    if grep -q "^VERSION=" "$CONFIG_FILE"; then
        sed -i "s/^VERSION=.*/VERSION=\"$version\"/" "$CONFIG_FILE"
    else
        echo "VERSION=\"$version\"" >> "$CONFIG_FILE"
    fi

    echo "VERSION has been set to $version in $CONFIG_FILE"
}

# Function to show the exit menu
show_exit() {
    bash /pg/installer/menu_exit.sh
}

# Main installation function
main_install() {
    create_directories
    check_and_install_docker

    # Determine if Alpha or Beta installation based on argument
    if [[ "$1" == "alpha" ]]; then
        download_repository
        update_config_version "PG Alpha"
    elif [[ "$1" == "beta" ]]; then
        check_and_install_unzip
        releases=$(fetch_releases)
        display_releases "$releases"

        # Prompt user to select a version
        echo ""
        read -p "Which Beta version do you want to install? " selected_version

        if echo "$releases" | grep -q "^${selected_version}$"; then
            echo "Proceeding with version $selected_version installation..."
            download_and_extract_beta "$selected_version"
            update_config_version "$selected_version"
        else
            echo "Invalid version selected. Exiting installation."
            exit 1
        fi
    else
        echo "Please specify 'alpha' or 'beta' as an argument to install."
        exit 1
    fi

    # Source the commands.sh script and run the create_command_symlinks function
    source /pg/installer/commands.sh
    create_command_symlinks

    show_exit
}

# Run the installation
main_install "$1"