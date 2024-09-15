#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

# Function to check and install unzip if not present
check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo "unzip not found. Installing unzip..."
        sudo apt-get update
        sudo apt-get install -y unzip
        echo "unzip has been installed."
    fi
}

# Function to fetch all releases from GitHub and filter them
fetch_releases() {
    curl -s https://api.github.com/repos/plexguide/PlexGuide.com/releases | jq -r '.[].tag_name' | grep -E '^11\.[0-9]\.B[0-9]+' | sort -r | head -n 50
}

# Function to create directories with the correct permissions
create_directories() {
    echo "Creating necessary directories..."

    directories=(
        "/pg/config"
        "/pg/scripts"
        "/pg/apps"
        "/pg/stage"
        "/pg/installer"
    )

    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo "Created $dir"
        else
            echo "$dir already exists"
        fi
        chown -R 1000:1000 "$dir"
        chmod -R +x "$dir"
    done
}

# Function to move folders from /pg/stage/mods/ to /pg/
move_folders() {
    echo "Moving folders from /pg/stage/mods/ to /pg/..."

    if [[ -d "/pg/stage/mods" ]]; then
        for folder in /pg/stage/mods/*; do
            foldername=$(basename "$folder")

            # Remove the existing folder in /pg/$foldername
            if [[ -d "/pg/$foldername" ]]; then
                rm -rf "/pg/$foldername"
                echo "Removed existing folder: /pg/$foldername"
            fi

            # Copy the folder from /pg/stage/mods/ to /pg/
            cp -r "/pg/stage/mods/$foldername" "/pg/$foldername"
            echo "Copied $foldername to /pg/"

            # Set permissions and ownership for the folder and its contents
            chown -R 1000:1000 "/pg/$foldername"
            chmod -R +x "/pg/$foldername"
            echo "Set permissions and ownership for /pg/$foldername and its contents"
        done
    else
        echo "Source directory /pg/stage/mods does not exist. No folders to move."
        exit 1
    fi
}

# Function to download and extract the selected release
download_and_extract() {
    local selected_version="$1"
    local url="https://github.com/plexguide/PlexGuide.com/archive/refs/tags/${selected_version}.zip"
    
    echo "Downloading and extracting ${selected_version}..."
    curl -L -o /pg/stage/release.zip "$url"
    
    unzip -o /pg/stage/release.zip -d /pg/stage/
    local extracted_folder="/pg/stage/PlexGuide.com-${selected_version}"
    
    if [[ -d "$extracted_folder" ]]; then
        echo "Found extracted folder: $extracted_folder"
                
        # Move all folders from /pg/stage/mods/ to /pg/
        move_folders

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
    local selected_version="$1"
    local config_file="/pg/config/config.cfg"

    if [[ ! -f "$config_file" ]]; then
        echo "Creating config file at $config_file"
        touch "$config_file"
    fi

    if grep -q "^VERSION=" "$config_file"; then
        sed -i "s/^VERSION=.*/VERSION=\"$selected_version\"/" "$config_file"
    else
        echo "VERSION=\"$selected_version\"" >> "$config_file"
    fi

    echo "VERSION has been set to $selected_version in $config_file"
}

# Function to display releases
display_releases() {
    releases="$1"
    echo -e "${RED}PG Beta Releases:${NC}"
    echo ""
    line_length=0
    first_release=true
    for release in $releases; do
        if (( line_length + ${#release} + 1 > 80 )); then
            echo ""
            line_length=0
        fi
        if $first_release; then
            echo -n -e "${ORANGE}$release${NC} "
            first_release=false
        else
            echo -n "$release "
        fi
        line_length=$((line_length + ${#release} + 1))
    done
    echo "" # New line after displaying all releases
}

show_exit() {
    bash /pg/installer/menu_exit.sh
}

# Main logic
while true; do
    clear
    releases=$(fetch_releases)
    
    if [[ -z "$releases" ]]; then
        echo "No releases found starting with '11' and containing 'B'."
        exit 1
    fi

    display_releases "$releases"
    echo ""
    read -p "Which version do you want to install? " selected_version

    if echo "$releases" | grep -q "^${selected_version}$"; then
        echo ""
        random_pin=$(printf "%04d" $((RANDOM % 10000)))
        while true; do
            read -p "$(echo -e "Type [${RED}${random_pin}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" response
            if [[ "$response" == "$random_pin" ]]; then
                check_and_install_unzip
                check_and_install_docker

                create_directories
                download_and_extract "$selected_version"
                update_config_version "$selected_version"

                # Source the commands.sh script and run the create_command_symlinks function
                source /pg/installer/commands.sh
                create_command_symlinks
                show_exit
                exit 0
            elif [[ "${response,,}" == "z" ]]; then
                echo "Installation canceled."
                exit 0
            else
                echo "Invalid input. Please try again."
            fi
        done
    else
        echo "Invalid version. Please select a valid version from the list."
    fi
done
