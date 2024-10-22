#!/bin/bash

# Path to the configuration file
CONFIG_FILE="/pg/config/pgfork.cfg"
CONFIG_VERSION="/pg/config/config.cfg"
COMMANDS_SCRIPT="/pg/installer/commands.sh"

# ANSI color codes
LIGHT_RED="\033[1;31m"
LIGHT_YELLOW="\033[1;33m"
LIGHT_GREEN="\033[1;32m"
LIGHT_BLUE="\033[1;34m"
PURPLE="\033[0;35m"
HOT_PINK="\033[1;35m"
NC="\033[0m" # No color

# Default values
user="plexguide"
repo="plexguide.com"
branch="v11"

# Function to validate GitHub repository and branch
validate_github_repo_and_branch() {
    local api_url="https://api.github.com/repos/${user}/${repo}/branches/${branch}"
    if curl --output /dev/null --silent --head --fail "$api_url"; then
        return 0
    else
        return 1
    fi
}

# Function to set or update the VERSION in the config file
set_config_version() {
    if [[ ! -f "$CONFIG_VERSION" ]]; then
        echo "Creating config file at $CONFIG_VERSION"
        echo 'VERSION="PG Alpha"' > "$CONFIG_VERSION"
    fi

    version_string="Fork - $user/$repo ($branch)"

    # Use awk to replace the entire line containing VERSION
    awk -v new_version="$version_string" '/^VERSION=/{$0="VERSION=\"" new_version "\""} 1' "$CONFIG_VERSION" > "${CONFIG_VERSION}.tmp" && mv "${CONFIG_VERSION}.tmp" "$CONFIG_VERSION"

    echo "VERSION has been updated to \"$version_string\" in $CONFIG_VERSION"
}

# Check if the configuration file exists, if not, create it
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Creating config file at $CONFIG_FILE"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
    echo "user=\"$user\"" > "$CONFIG_FILE"
    echo "repo=\"$repo\"" >> "$CONFIG_FILE"
    echo "branch=\"$branch\"" >> "$CONFIG_FILE"
else
    # Source the configuration file to load existing values
    source "$CONFIG_FILE"
fi

# Function to ensure commands.sh exists and is executable
ensure_commands_script() {
    if [[ ! -f "$COMMANDS_SCRIPT" ]]; then
        echo "commands.sh not found. Downloading from GitHub..."
        mkdir -p "$(dirname "$COMMANDS_SCRIPT")"
        curl -o "$COMMANDS_SCRIPT" https://raw.githubusercontent.com/plexguide/Installer/v11/commands.sh
        chmod +x "$COMMANDS_SCRIPT"
        chown 1000:1000 "$COMMANDS_SCRIPT"
    fi
}

# Function to create command symlinks
create_command_symlinks() {
    ensure_commands_script
    source "$COMMANDS_SCRIPT"
    create_command_symlinks
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

# Function to download and place files into /pg/stage/
download_repository() {
    echo "Preparing /pg/stage/ directory..."

    if [[ -d "/pg/stage/" ]]; then
        rm -rf /pg/stage/*
        rm -rf /pg/stage/.* 2>/dev/null || true
        echo "Cleared /pg/stage/ directory."
    fi

    # Download the repository using the user, repo, and branch variables
    echo "Downloading repository from ${user}/${repo} on branch ${branch}..."
    git clone -b "$branch" "https://github.com/${user}/${repo}.git" /pg/stage/

    if [[ $? -eq 0 ]]; then
        echo "Repository successfully downloaded to /pg/stage/."
    else
        echo "Failed to download the repository. Please check your network connection and repository details."
        exit 1
    fi
}

# Function to move content from /pg/stage/mods/ to /pg/
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

# New Function: Deploy PG Fork with updated 4-digit PIN format
deploy_pg_fork() {

                create_directories
                download_repository
                move_folders
                set_config_version  # Call set_config_version here
                create_command_symlinks
                show_exit
                exit 0
}

show_exit() {
    sudo plexguide
    exit 0
}

menu_commands() {
    echo "Returning to the main menu..."
    bash /pg/installer/menu_commands.sh
}

# Ensure commands.sh exists and create symlinks at the start
ensure_commands_script
create_command_symlinks

# Start the PG Fork menu
deploy_pg_fork
