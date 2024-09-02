#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

# Function to ensure /pg/stage directory exists
ensure_stage_directory() {
    if [[ ! -d "/pg/stage" ]]; then
        mkdir -p /pg/stage
        echo "Created /pg/stage directory."
    fi
}

# Function to check and install unzip if not present using Ansible
check_and_install_unzip() {
    local playbook_file="/pg/stage/install_unzip_playbook.yml"

    # Ensure the /pg/stage directory exists
    ensure_stage_directory

    # Generate the Ansible playbook
    cat <<EOF > "$playbook_file"
---
- name: Check and install unzip if not present
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Check if unzip is installed
      command: which unzip
      register: unzip_check
      ignore_errors: true

    - name: Install unzip if not found
      apt:
        name: unzip
        state: present
      when: unzip_check.rc != 0
EOF

    echo "Running Ansible playbook to check and install unzip..."
    ansible-playbook "$playbook_file" -i localhost, --connection=local
}

# Function to check and install Docker if not installed
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "\e[38;5;196mD\e[38;5;202mO\e[38;5;214mC\e[38;5;226mK\e[38;5;118mE\e[38;5;51mR \e[38;5;201mI\e[38;5;141mS \e[38;5;93mI\e[38;5;87mN\e[38;5;129mS\e[38;5;166mT\e[38;5;208mA\e[38;5;226mL\e[38;5;190mL\e[38;5;82mI\e[38;5;40mN\e[38;5;32mG\e[0m"
        sleep 0.5
        chmod +x /pg/installer/docker.sh
        bash /pg/installer/docker.sh
    fi
}

# Function to fetch all releases from GitHub and filter them
fetch_releases() {
    curl -s https://api.github.com/repos/plexguide/PlexGuide.com/releases | jq -r '.[].tag_name' | grep -E '^11\.[0-9]\.B[0-9]+' | sort -r | head -n 50
}

# Function to create directories with the correct permissions using Ansible
create_directories() {
    local playbook_file="/pg/stage/create_directories_playbook.yml"

    # Ensure the /pg/stage directory exists
    ensure_stage_directory

    # Generate the Ansible playbook
    cat <<EOF > "$playbook_file"
---
- name: Create necessary directories and set permissions
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Ensure directories exist with proper ownership and permissions
      file:
        path: "{{ item }}"
        state: directory
        owner: 1000
        group: 1000
        mode: '0755'
      loop:
        - /pg/config
        - /pg/scripts
        - /pg/apps
        - /pg/stage
        - /pg/installer
EOF

    echo "Running Ansible playbook to create directories..."
    ansible-playbook "$playbook_file" -i localhost, --connection=local
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