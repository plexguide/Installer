#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Wrapper script path
WRAPPER_SCRIPT="/usr/local/bin/pg_wrapper.sh"

# Wrapper script content
cat << 'EOF' > "$WRAPPER_SCRIPT"
#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Function to repair /pg directory
repair_pg_directory() {
    local install_script_url="https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh"
    local tmp_dir="/pg/tmp"
    local tmp_script="$tmp_dir/install_menu_tmp.sh"
    sudo mkdir -p "$tmp_dir"
    curl -sL "$install_script_url" -o "$tmp_script"
    chmod +x "$tmp_script"
    bash "$tmp_script"
}

# Check if /pg directory and script exist
if [[ ! -d "/pg" || ! -f "/pg/scripts/menu.sh" ]]; then
    echo -e "${RED}Warning: The /pg directory or required scripts are missing.${NC}"
    while true; do
        repair_code=$(printf "%04d" $((RANDOM % 10000)))
        echo -e "Do you want to repair this? Type [${GREEN}${BOLD}${repair_code}${NC}] for Yes or [${RED}${BOLD}${repair_code}${NC}] for No: "
        read -r choice

        if [[ "$choice" == "$repair_code" ]]; then
            echo -e "${GREEN}Starting repair process...${NC}"
            repair_pg_directory
            break
        elif [[ "$choice" == "$repair_code" ]]; then
            echo -e "${RED}Are you really sure? PlexGuide commands will stop working.${NC}"
            echo -e "Type [${GREEN}${BOLD}${repair_code}${NC}] for Yes or [${RED}${BOLD}${repair_code}${NC}] for No: "
            read -r confirm_choice

            if [[ "$confirm_choice" == "$repair_code" ]]; then
                echo -e "${GREEN}Starting repair process...${NC}"
                repair_pg_directory
                break
            else
                echo -e "${RED}Commands will stop working once you exit.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Invalid input. Please enter the correct 4-digit code.${NC}"
        fi
    done
else
    # Execute the intended command if /pg exists
    exec /pg/scripts/menu.sh
fi
EOF

# Make the wrapper script executable
sudo chmod +x "$WRAPPER_SCRIPT"

# Function to create symbolic links for command scripts
create_command_symlinks() {
    echo "Creating command symlinks..."

    # Define an associative array with command names as keys and script paths as values
    declare -A commands=(
        ["plexguide"]="$WRAPPER_SCRIPT"
        ["pg"]="$WRAPPER_SCRIPT"
        ["pgalpha"]="$WRAPPER_SCRIPT"
        ["pgbeta"]="$WRAPPER_SCRIPT"
        ["pgfork"]="$WRAPPER_SCRIPT"
    )

    # Loop over the associative array to create symbolic links and set executable permissions
    for cmd in "${!commands[@]}"; do
        sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"
        sudo chown 1000:1000 "/usr/local/bin/$cmd"
        sudo chmod 755 "/usr/local/bin/$cmd"
    done

    echo "Command symlinks created successfully."
}

# Function to set up the pginstall command
setup_pginstall_command() {
    echo "Setting up pginstall command..."

    local install_script_url="https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh"
    local tmp_dir="/pg/tmp"
    local tmp_script="$tmp_dir/install_menu_tmp.sh"

    sudo mkdir -p "$tmp_dir"

    cat << EOF | sudo tee /usr/local/bin/pginstall > /dev/null
#!/bin/bash
echo "Downloading and executing the PG installer..."

curl -sL "$install_script_url" -o "$tmp_script"
chmod +x "$tmp_script"
bash "$tmp_script"
EOF

    sudo chown 1000:1000 /usr/local/bin/pginstall
    sudo chmod 755 /usr/local/bin/pginstall

    echo "pginstall command setup complete. You can now use the pginstall command to run the installer."
}

# Main script execution
check_pg_directory  # Ensure the /pg directory and scripts exist or repair
create_command_symlinks  # Create symlinks to the wrapper script
setup_pginstall_command  # Set up the pginstall command

echo "Setup complete. You can now use the pginstall command to run the installer."
