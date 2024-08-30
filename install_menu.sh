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
    local packages=("jq" "git" "sed" "awk" "coreutils" "cut")
    
    # Loop through each package and install if not found
    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            echo "Installing missing package: $package..."
            sudo apt-get update
            sudo apt-get install -y "$package"
        else
            echo "Package $package is already installed."
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
    echo -e "Note: Stable Edition will be Released When Ready."
    echo ""  # Space below the note
    echo -e "[${RED}A${NC}] PG Alpha"
    echo -e "[${PURPLE}B${NC}] PG Beta"
    echo -e "[${LIGHT_BLUE}F${NC}] PG Fork"
    echo -e "[Z] Exit"
    echo ""
}

# Function to validate the user's choice
validate_choice() {
    local choice="$1"
    case ${choice,,} in
        a)
            echo "Selected PG Alpha." && echo ""
            prompt_for_pin  # Prompt for PIN before downloading and installing
            download_installer_repo  # Download the main installer repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_alpha.sh"
            exit 0
            ;;
        b)
            echo "Selected PG Beta." && echo ""
            prompt_for_pin  # Prompt for PIN before downloading and installing
            download_installer_repo  # Download the main installer repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_beta.sh"
            exit 0
            ;;
        f)
            echo "Selected PG Fork." && echo ""
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
    local random_pin=$(printf "%04d" $((RANDOM % 10000)))

    while true; do
        read -p "$(echo -e "Type [${RED}${random_pin}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" response
        if [[ "$response" == "$random_pin" ]]; then
            echo "Correct PIN entered. Proceeding with installation..."
            return 0
        elif [[ "${response,,}" == "z" ]]; then
            echo "Installation canceled."
            exit 0
        else
            echo "Invalid input. Please try again."
        fi
    done
}

# Function to download and run the selected installation script
run_install_script() {
    local script_url="$1"
    local installer_dir="/pg/installer"
    local script_file="$installer_dir/install_script.sh"

    # Prepare the /pg/installer directory
    prepare_installer_directory

    echo "Downloading the installation script..."
    curl -sL "$script_url" -o "$script_file"
    
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

# Main loop to display the interface and handle user input
while true; do
    check_and_install_packages  # Check for required packages at the start
    display_interface
    read -p "Enter your choice: " user_choice
    validate_choice "$user_choice"
    
    # Direct exit if 'z' or 'Z' is chosen
    if [[ "${user_choice,,}" == "z" ]]; then
        exit 0
    fi
done
