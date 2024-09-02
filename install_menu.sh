#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
LIGHT_BLUE="\033[1;34m"
NC="\033[0m" # No color

# Function to install Ansible
install_ansible() {
    if ! command -v ansible &> /dev/null; then
        echo -e "${GREEN}Ansible not found. Installing Ansible...${NC}"
        # Detect the OS and VERSION
        if [ -f /etc/os-release ]; then
            . /etc/os-release
        else
            echo -e "${RED}Cannot determine the operating system. Exiting...${NC}"
            exit 1
        fi

        # Check if the OS is Ubuntu or Debian and call the appropriate function
        if [[ "$ID" == "ubuntu" && ( "$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04" ) ]]; then
            sudo apt update -y
            sudo apt install -y software-properties-common
            sudo add-apt-repository --yes --update ppa:ansible/ansible
            sudo apt update -y
            sudo apt install -y ansible
        elif [[ "$ID" == "debian" && "$VERSION_ID" == "12" ]]; then
            sudo apt update -y
            sudo apt install -y software-properties-common
            sudo apt install -y ansible
        else
            echo -e "${RED}This script supports only Ubuntu 22.04, Ubuntu 24.04, and Debian 12. Exiting...${NC}"
            exit 1
        fi

        echo -e "${GREEN}Ansible installation complete. Verifying the installation...${NC}"
        ansible --version

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Ansible has been installed successfully!${NC}"
        else
            echo -e "${RED}Ansible installation failed. Please check the error messages above.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Ansible is already installed.${NC}"
    fi
}

# Function to check and install required packages
check_and_install_packages() {

    # Generate the Ansible playbook
    cat <<EOF > "/pg/stage/install_packages_playbook.yml"
---
- name: Check and install required packages
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Ensure required packages are installed
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - jq
        - git
        - sed
        - awk
        - cut
EOF
    ansible-playbook "/pg/stage/install_packages_playbook.yml" -i localhost,
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
    install_ansible  # Install Ansible if not present
    check_and_install_packages  # Check for required packages at the start
    display_interface
    read -p "Enter your choice: " user_choice
    validate_choice "$user_choice"
    
    # Direct exit if 'z' or 'Z' is chosen
    if [[ "${user_choice,,}" == "z" ]]; then
        exit 0
    fi
done