#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
LIGHT_BLUE="\033[1;34m"
NC="\033[0m" # No color

# Function to check and install required packages
check_and_install_packages() {
    # List of required packages
    local packages=("jq" "git" "sed" "awk" "cut")
    
    # Loop through each package and install if not found
    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            echo "Installing missing package: $package..."
            sudo apt-get update
            sudo apt-get install -y "$package"
        fi
    done
}

# Prepare the installer directory
prepare_installer_directory() {
    local installer_dir="/pg/installer"
    
    # Create the /pg/installer directory if it doesn't exist
    if [[ ! -d "$installer_dir" ]]; then
        mkdir -p "$installer_dir"
    fi
}

# Function to download the main Installer repository
download_installer_repo() {
    local installer_dir="/pg/installer"
    local repo_url="https://github.com/plexguide/Installer.git"

    echo "Downloading Installer repository..."

    # Prepare the /pg/installer directory
    prepare_installer_directory

    # Clear the directory before downloading
    rm -rf "$installer_dir"/*
    rm -rf "$installer_dir"/.* 2>/dev/null || true

    # Clone the repository
    git clone "$repo_url" "$installer_dir"

    # Check if the clone was successful
    if [[ $? -eq 0 ]]; then
        echo "Installer repository successfully downloaded to $installer_dir."
        
        # Set ownership and permissions
        chown -R 1000:1000 "$installer_dir"
        chmod -R +x "$installer_dir"
    else
        echo "Failed to download the Installer repository. Please check your internet connection."
        exit 1
    fi
}

# Function to display the interface
display_interface() {
    clear
    echo -e "${CYAN}PG Edition Selection Interface${NC}"
    echo -e "Note: Thank You for Using PlexGuide!"
    echo ""  # Space below the note
    echo -e "[${GREEN}S${NC}] PG Stable"
    echo -e "[${PURPLE}B${NC}] PG Beta"
    echo -e "[${RED}D${NC}] PG Dev"
    echo -e "[${LIGHT_BLUE}F${NC}] PG Fork"
    echo -e "[Z] Exit"
    echo ""
}

# Function to check and install Docker if not installed
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${GREEN}Installing Docker...${NC}"
        
        # Basic Commands
        mkdir -p /pg/installer
        curl -fsSL https://raw.githubusercontent.com/plexguide/Installer/v11/docker.sh -o /pg/installer/docker.sh
        chmod +x /pg/installer/docker.sh
        bash /pg/installer/docker.sh
    fi
}

# Function to check and install Docker Compose if not installed
check_and_install_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Installing Docker-Compose...${NC}"
        mkdir -p /pg/installer
        curl -fsSL https://raw.githubusercontent.com/plexguide/Installer/v11/compose.sh -o /pg/installer/compose.sh
        chmod +x /pg/installer/compose.sh
        bash /pg/installer/compose.sh
    fi
}

# Function to validate the user's choice
validate_choice() {
    local choice="$1"
    case ${choice,,} in
        d)
            echo "Selected PG Dev."
            prompt_for_pin  # Prompt for PIN before downloading and installing
            download_installer_repo  # Download the main installer repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_dev.sh"
            exit 0
            ;;
        s)
            echo "Selected PG Stable."
            prompt_for_pin  # Prompt for PIN before downloading and installing
            download_installer_repo  # Download the main installer repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_stable.sh"
            exit 0
            ;;
        b)
            echo "Selected PG Beta."
            prompt_for_pin  # Prompt for PIN before downloading and installing
            download_installer_repo  # Download the main installer repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_beta.sh"
            exit 0
            ;;
        f)
            echo "Selected PG Fork."
            prompt_for_pin  # Prompt for PIN before downloading and installing
            download_installer_repo  # Download the main installer repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_fork.sh"
            exit 0
            ;;
        z)
            echo "Exiting the selection interface."
            echo ""
            exit 0
            ;;
        *)
            echo "Invalid input. Please try again."
            ;;
    esac
}

# Function to prompt for a 4-digit PIN before proceeding
prompt_for_pin() {
    # Generate random 4-digit PINs
    pin_proceed=$((RANDOM % 9000 + 1000))  # Random 4-digit PIN for proceeding
    pin_exit=$((RANDOM % 9000 + 1000))     # Random 4-digit PIN for exiting

    while true; do
        echo -e "\nTo proceed, enter this PIN: \033[95m$pin_proceed\033[0m"  # Hot pink PIN for proceeding
        echo -e "To exit, enter this PIN: \033[32m$pin_exit\033[0m"           # Green PIN for exiting
        echo ""
        read -p "Enter PIN > " user_pin
        
        if [[ "$user_pin" == "$pin_proceed" ]]; then
            echo "Correct PIN entered. Proceeding with installation..."
            return 0
        elif [[ "$user_pin" == "$pin_exit" ]]; then
            echo "Installation canceled."
            exit 0
        else
            echo "Invalid PIN. Try again."
        fi
    done
}

# Function to download and run the selected installation script
run_install_script() {
    local script_url="$1"
    local installer_dir="/pg/installer"
    local script_file="$installer_dir/install_script.sh"
    local random_number=$(date +%s)  # Add a random query string to bypass cache

    # Append query string to force bypassing the cache
    script_url="${script_url}?nocache=$random_number"

    # Prepare the /pg/installer directory
    prepare_installer_directory

    echo "Downloading the installation script..."
    curl -H 'Cache-Control: no-cache' -sL "$script_url" -o "$script_file"
    
    # Check if the script was downloaded successfully
    if [[ -f "$script_file" ]]; then
        echo "Setting execute permissions and running the installation script..."
        chmod +x "$script_file"
        bash "$script_file"
        exit 0
    else
        echo "Failed to download the installation script. Please check your internet connection and try again."
        exit 1
    fi
}

# To execute at the start
check_and_install_packages
check_and_install_docker
check_and_install_compose

# Main loop to display the interface and handle user input
while true; do
    display_interface
    read -p "Make a Choice > " user_choice
    validate_choice "$user_choice"
    
    # Direct exit if 'z' or 'Z' is chosen
    if [[ "${user_choice,,}" == "z" ]]; then
        exit 0
    fi
done
