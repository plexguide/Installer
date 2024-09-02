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

# Function to check and install Docker if not installed
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "\e[38;5;196mD\e[38;5;202mO\e[38;5;214mC\e[38;5;226mK\e[38;5;118mE\e[38;5;51mR \e[38;5;201mI\e[38;5;141mS \e[38;5;93mI\e[38;5;87mN\e[38;5;129mS\e[38;5;166mT\e[38;5;208mA\e[38;5;226mL\e[38;5;190mL\e[38;5;82mI\e[38;5;40mN\e[38;5;32mG\e[0m"
        sleep 0.5
        chmod +x /pg/installer/docker.sh
        bash /pg/installer/docker.sh
    fi
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

# Function to dynamically create and execute an Ansible playbook
ansible_download_and_extract() {
    local selected_version="$1"
    local playbook_file="/pg/stage/download_extract_playbook.yml"
    local extracted_folder="/pg/stage/PlexGuide.com-${selected_version}"
    local release_url="https://github.com/plexguide/PlexGuide.com/archive/refs/tags/${selected_version}.zip"

    # Create the Ansible playbook file
    cat <<EOF > "$playbook_file"
---
- name: Download and extract PlexGuide release
  hosts: localhost
  tasks:
    - name: Download the selected release
      get_url:
        url: $release_url
        dest: /pg/stage/release.zip

    - name: Extract the release zip
      unarchive:
        src: /pg/stage/release.zip
        dest: /pg/stage/
        remote_src: yes

    - name: Clear /pg/scripts/ directory
      shell: rm -rf /pg/scripts/*

    - name: Move extracted scripts to /pg/scripts/
      shell: |
        if [[ -d "$extracted_folder/mods/scripts" ]]; then
          mv $extracted_folder/mods/scripts/* /pg/scripts/
        fi

    - name: Set permissions on /pg/scripts/
      file:
        path: /pg/scripts/
        owner: 1000
        group: 1000
        mode: '0755'
        recurse: yes

    - name: Clear /pg/stage/ directory
      shell: rm -rf /pg/stage/*
EOF

    echo "Running Ansible playbook to download and extract ${selected_version}..."
    ansible-playbook "$playbook_file"
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

# Main logic
while true; do
    clear
    selected_version="11.0.B01"  # Example version for demonstration

    echo ""
    random_pin=$(printf "%04d" $((RANDOM % 10000)))
    while true; do
        read -p "$(echo -e "Type [${RED}${random_pin}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" response
        if [[ "$response" == "$random_pin" ]]; then
            check_and_install_unzip
            check_and_install_docker

            create_directories
            ansible_download_and_extract "$selected_version"
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
done