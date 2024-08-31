#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
LIGHT_BLUE="\033[1;34m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Additional rainbow colors for the menu options
BRIGHT_RED="\033[1;31m"
ORANGE="\033[1;33m"
YELLOW="\033[1;33m"
BRIGHT_GREEN="\033[1;32m"
BRIGHT_BLUE="\033[1;34m"
BRIGHT_MAGENTA="\033[1;35m"
BRIGHT_CYAN="\033[1;36m"

# Define the path to the support script
SUPPORT_SCRIPT="/pg/installer/support.sh"

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
    [[ ! -d "$installer_dir" ]] && mkdir -p "$installer_dir"
}

# Download the main Installer repository
download_installer_repo() {
    local installer_dir="/pg/installer"
    local repo_url="https://github.com/plexguide/Installer.git"

    echo "Downloading Installer repository..."
    prepare_installer_directory
    rm -rf "$installer_dir"/* "$installer_dir"/.* 2>/dev/null || true
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

# Display the interface
display_interface() {
    clear
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}PG Edition Selection Interface${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""  # Blank line for separation

    # Display options with rainbow colors and bold formatting
    echo -e "[${BRIGHT_RED}${BOLD}A${NC}] PG Alpha"
    echo -e "[${BRIGHT_GREEN}${BOLD}B${NC}] PG Beta"
    echo -e "[${BRIGHT_BLUE}${BOLD}F${NC}] PG Fork"
    echo -e "[${BRIGHT_CYAN}${BOLD}Z${NC}] Exit"
    echo ""
}

# Validate user's choice
validate_choice() {
    case ${1,,} in
        a)
            echo "Selected PG Alpha."
            prompt_for_pin
            download_installer_repo
            run_support_script "alpha"
            ;;
        b)
            echo "Selected PG Beta."
            prompt_for_pin
            download_installer_repo
            run_support_script "beta"
            ;;
        f)
            echo "Selected PG Fork."
            prompt_for_pin
            download_installer_repo
            run_install_script "https://raw.githubusercontent.com/plexguide/Installer/v11/install_fork.sh"
            ;;
        z)
            echo "Exiting the selection interface."
            exit 0
            ;;
        *)
            echo "Invalid input. Please try again."
            ;;
    esac
}

# Prompt for a 4-digit PIN before proceeding
prompt_for_pin() {
    local random_pin=$(printf "%04d" $((RANDOM % 10000)))
    while true; do
        read -p "$(echo -e "Type [${RED}${random_pin}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" response
        case ${response,,} in
            "$random_pin") 
                echo "Correct PIN entered. Proceeding with installation..."
                return 0
                ;;
            z) 
                echo "Installation canceled."
                exit 0
                ;;
            *)
                echo "Invalid input. Please try again."
                ;;
        esac
    done
}

# Run the `support.sh` script with the provided version argument
run_support_script() {
    if [[ -f "$SUPPORT_SCRIPT" ]]; then
        echo "Running support script for version: $1..."
        bash "$SUPPORT_SCRIPT" "$1"
    else
        echo "Support script not found at $SUPPORT_SCRIPT. Please check your installation."
        exit 1
    fi
}

# Download and run the selected installation script for Fork
run_install_script() {
    local script_url="$1"
    local script_file="/pg/installer/install_script.sh"

    prepare_installer_directory
    echo "Downloading the installation script..."
    curl -sL "$script_url" -o "$script_file"

    if [[ -f "$script_file" ]]; then
        echo "Running the installation script..."
        chmod +x "$script_file"
        bash "$script_file"
    else
        echo "Failed to download the installation script. Please check your internet connection."
        exit 1
    fi
}

# Main loop to display the interface and handle user input
while true; do
    check_and_install_packages
    display_interface
    read -p "Enter your choice: " user_choice
    validate_choice "$user_choice"
done