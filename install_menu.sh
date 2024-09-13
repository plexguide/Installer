#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
LIGHT_BLUE="\033[1;34m"
BRIGHT_BLUE="\033[1;94m" # Bright blue
HOT_PINK="\033[0;95m" # Hot pink
BOLD="\033[1m"
NC="\033[0m" # No color

# Function to check and install required packages
check_and_install_packages() {
    local packages=("jq" "git" "sed" "awk" "cut")
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
    if [[ ! -d "$installer_dir" ]]; then
        mkdir -p "$installer_dir"
    fi
}

# Function to download the main Installer repository
download_installer_repo() {
    local installer_dir="/pg/installer"
    local repo_url="https://github.com/plexguide/Installer.git"
    echo "Downloading Installer repository..."
    prepare_installer_directory
    rm -rf "$installer_dir"/*
    rm -rf "$installer_dir"/.* 2>/dev/null || true
    git clone "$repo_url" "$installer_dir"
    if [[ $? -eq 0 ]]; then
        echo "Installer repository successfully downloaded to $installer_dir."
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
    echo -e "${CYAN}${BOLD}PG Edition Selection Interface${NC}"
    echo -e "Note: Stable Edition will be Released When Ready."
    echo ""  # Space below the note
    echo -e "[${RED}${BOLD}A${NC}] PG Alpha"
    echo -e "[${PURPLE}${BOLD}B${NC}] PG Beta"
    echo -e "[${BRIGHT_BLUE}${BOLD}F${NC}] PG Fork"
    echo -e "[${HOT_PINK}${BOLD}Z${NC}] Exit"
    echo ""
}

# Function to check and install Docker if not installed
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${GREEN}Installing Docker...${NC}"
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

# Function to prompt user for PINs
handle_pin() {
    local action=$1
    while true; do
        echo ""
        # Generate new PINs every time
        pin_forward=$((RANDOM % 9000 + 1000))
        pin_exit=$((RANDOM % 9000 + 1000))

        echo -e "To proceed, enter this PIN: ${HOT_PINK}${BOLD}$pin_forward${NC}"
        echo -e "To exit, enter this PIN: ${GREEN}${BOLD}$pin_exit${NC}"
        echo ""
        read -p "Enter PIN > " user_pin

        if [[ "$user_pin" == "$pin_forward" ]]; then
            echo "Correct PIN entered. Proceeding with installation..."
            return 0
        elif [[ "$user_pin" == "$pin_exit" ]]; then
            clear
            echo -e "${RED}WARNING:${NC} If you exit without installing, you will need to run the install command again."
            exit 0
        else
            echo "Invalid PIN. Try again."
        fi
    done
}

# Function to validate the user's choice
validate_choice() {
    local choice="$1"
    case ${choice,,} in
        a)
            echo "Selected PG Alpha." && echo ""
            handle_pin "forward"
            download_installer_repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_alpha.sh"
            exit 0
            ;;
        b)
            echo "Selected PG Beta." && echo ""
            handle_pin "forward"
            download_installer_repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_beta.sh"
            exit 0
            ;;
        f)
            echo "Selected PG Fork." && echo ""
            handle_pin "forward"
            download_installer_repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_fork.sh"
            exit 0
            ;;
        z)
            if [[ ! -d /pg/scripts ]]; then
                echo -e "${RED}WARNING:${NC} If you exit without installing, you will have to run the install command again."
                handle_pin "exit"
            else
                clear
                echo "You must run the install command to run PG again."
                exit 0
            fi
            ;;
        *)
            echo "Invalid input. Please try again."
            ;;
    esac
}

# Function to download and run the selected installation script
run_install_script() {
    local script_url="$1"
    local installer_dir="/pg/installer"
    local script_file="$installer_dir/install_script.sh"
    prepare_installer_directory
    echo "Downloading the installation script..."
    curl -sL "$script_url" -o "$script_file"
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
    read -p "Enter your choice: " user_choice
    validate_choice "$user_choice"
done
