#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GOLD='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info() {
    echo -e "${BOLD}${GOLD}[INFO] $1${NC}"
}

warn() {
    echo -e "${BOLD}${RED}[WARN] $1${NC}"
}

error() {
    echo -e "${BOLD}${RED}[ERROR] $1${NC}"
}

# Function to execute the adduser.sh script
execute_adduser_script() {
    local adduser_script_url="https://raw.githubusercontent.com/plexguide/Installer/refs/heads/v11/adduser.sh"
    local tmp_script="/tmp/adduser_tmp.sh"

    info "Downloading and executing the adduser script..."

    # Download the adduser script
    if curl -sL "$adduser_script_url" -o "$tmp_script"; then
        # Set the script as executable
        chmod +x "$tmp_script"

        # Execute the script
        bash "$tmp_script"

        # Remove the temporary script
        rm -f "$tmp_script"

        info "User setup completed."
    else
        error "Failed to download the adduser script. Please check your internet connection and try again."
        exit 1
    fi
}

# Function to create symbolic links for command scripts
create_command_symlinks() {
    info "Creating command symlinks..."

    # Define an associative array with command names as keys and script paths as values
    declare -A commands=(
        ["plexguide"]="/pg/scripts/menu.sh"
        ["pg"]="/pg/scripts/menu.sh"
        ["pgdev"]="/pg/installer/install_dev.sh"
        ["pgbeta"]="/pg/installer/install_beta.sh"
        ["pgfork"]="/pg/installer/install_fork.sh"
        ["pgstable"]="/pg/installer/install_stable.sh"
    )

    # Loop over the associative array to create symbolic links and set executable permissions
    for cmd in "${!commands[@]}"; do
        # Create the symbolic link with force option to overwrite if it exists
        sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"

        # Set ownership to 1000:1000
        sudo chown 1000:1000 "/usr/local/bin/$cmd"

        # Set the executable permission to 755 (read and execute for everyone)
        sudo chmod 755 "/usr/local/bin/$cmd"
        
        info "Created symlink: $cmd -> ${commands[$cmd]}"
    done

    info "Command symlinks created successfully."
}

# Function to set up the pginstall command
setup_pginstall_command() {
    info "Setting up pginstall command..."

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

    info "pginstall command setup complete. You can now use the pginstall command to run the installer."
}

# Function to ensure all created commands are 1000:1000 and executable
ensure_command_permissions() {
    info "Ensuring correct permissions for all created commands..."

    local commands=("plexguide" "pg" "pgdev" "pgbeta" "pgfork" "pgstable" "pginstall")

    for cmd in "${commands[@]}"; do
        if [[ -f "/usr/local/bin/$cmd" ]]; then
            sudo chown 1000:1000 "/usr/local/bin/$cmd"
            sudo chmod 755 "/usr/local/bin/$cmd"
            info "Set permissions for $cmd: owner 1000:1000, mode 755"
        else
            warn "Command $cmd not found in /usr/local/bin"
        fi
    done

    info "Permissions check and update completed."
}

# Main script execution
execute_adduser_script
create_command_symlinks
setup_pginstall_command
ensure_command_permissions

info "Setup complete. You can now use the pginstall command to run the installer."