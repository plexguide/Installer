#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Function to check if /pg directory exists
check_pg_directory() {
    if [[ ! -d "/pg" ]]; then
        echo -e "${RED}Warning: The /pg directory is missing.${NC}"
        echo "PlexGuide commands are unable to work because the /pg folder is missing."

        # Generate random 4-digit codes for yes and no options
        yes_code=$(printf "%04d" $((RANDOM % 10000)))
        no_code=$(printf "%04d" $((RANDOM % 10000)))

        while true; do
            read -p "$(echo -e "Do you want to repair this? Type [${GREEN}${BOLD}${yes_code}${NC}] for Yes or [${RED}${BOLD}${no_code}${NC}] for No: ")" choice

            if [[ "$choice" == "$yes_code" ]]; then
                echo -e "${GREEN}Starting repair process...${NC}"
                repair_pg_directory
                break
            elif [[ "$choice" == "$no_code" ]]; then
                read -p "$(echo -e "${RED}Are you really sure? PlexGuide commands will stop working. Type [${GREEN}${BOLD}${yes_code}${NC}] for Yes or [${RED}${BOLD}${no_code}${NC}] for No: ")" confirm_choice
                if [[ "$confirm_choice" == "$yes_code" ]]; then
                    echo -e "${GREEN}Starting repair process...${NC}"
                    repair_pg_directory
                    break
                elif [[ "$confirm_choice" == "$no_code" ]]; then
                    echo -e "${RED}Commands will stop working once you exit.${NC}"
                    exit 1
                else
                    echo -e "${RED}Invalid input. Please enter the correct 4-digit code.${NC}"
                fi
            else
                echo -e "${RED}Invalid input. Please enter the correct 4-digit code.${NC}"
            fi
        done
    fi
}

# Function to repair /pg directory
repair_pg_directory() {
    # Define the URL of the install script
    local install_script_url="https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh"
    
    # Define the directory and script name for temporary storage
    local tmp_dir="/pg/tmp"
    local tmp_script="$tmp_dir/install_menu_tmp.sh"
    
    # Ensure the /pg directory and tmp directory exists
    sudo mkdir -p "$tmp_dir"
    
    # Download the installation script
    echo "Downloading the installation script..."
    curl -sL "$install_script_url" -o "$tmp_script"
    
    # Set the script as executable
    chmod +x "$tmp_script"
    
    # Execute the installation script
    echo "Executing the installation script..."
    bash "$tmp_script"
}

# Function to create symbolic links for command scripts
create_command_symlinks() {
    echo "Creating command symlinks..."

    # Define an associative array with command names as keys and script paths as values
    declare -A commands=(
        ["plexguide"]="/pg/scripts/menu.sh"
        ["pg"]="/pg/scripts/menu.sh"
        ["pgalpha"]="/pg/installer/install_alpha.sh"
        ["pgbeta"]="/pg/installer/install_beta.sh"
        ["pgfork"]="/pg/installer/install_fork.sh"
    )

    # Loop over the associative array to create symbolic links and set executable permissions
    for cmd in "${!commands[@]}"; do
        # Check if the script path exists before creating the symlink
        if [[ ! -f "${commands[$cmd]}" ]]; then
            echo -e "${RED}Error: ${commands[$cmd]} not found. Cannot create symlink for $cmd.${NC}"
            continue
        fi

        # Create the symbolic link with force option to overwrite if it exists
        sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"

        # Set ownership to 1000:1000
        sudo chown 1000:1000 "/usr/local/bin/$cmd"

        # Set the executable permission to 755 (read and execute for everyone)
        sudo chmod 755 "/usr/local/bin/$cmd"
    done

    echo "Command symlinks created successfully."
}

# Function to set up the pginstall command
setup_pginstall_command() {
    echo "Setting up pginstall command..."

    # Define the URL of the install script
    local install_script_url="https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh"

    # Define the directory and script name for temporary storage
    local tmp_dir="/pg/tmp"
    local tmp_script="$tmp_dir/install_menu_tmp.sh"

    # Ensure the temporary directory exists
    sudo mkdir -p "$tmp_dir"

    # Write the pginstall script that will download the install script to the tmp directory and execute it
    cat << EOF | sudo tee /usr/local/bin/pginstall > /dev/null
#!/bin/bash
echo "Downloading and executing the PG installer..."

# Download the installation script
curl -sL "$install_script_url" -o "$tmp_script"

# Set the script as executable
chmod +x "$tmp_script"

# Execute the script
bash "$tmp_script"
EOF

    # Set ownership and permissions for the pginstall script
    sudo chown 1000:1000 /usr/local/bin/pginstall
    sudo chmod 755 /usr/local/bin/pginstall

    echo "pginstall command setup complete. You can now use the pginstall command to run the installer."
}

# Main script execution
check_pg_directory
create_command_symlinks
setup_pginstall_command

echo "Setup complete. You can now use the pginstall command to run the installer."
