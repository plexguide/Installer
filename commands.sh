#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GOLD='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Define the default configuration file paths
CONFIG_FILE="/pg/config/pgfork.cfg"
CONFIG_VERSION="/pg/config/config.cfg"
COMMANDS_SCRIPT="/pg/installer/commands.sh"

# Default values
user="plexguide"
repo="plexguide.com"
branch="v11"

# Function to parse command-line arguments
parse_args() {
    skip_pin_check=false
    while getopts "n" opt; do
        case ${opt} in
            n)
                skip_pin_check=true
                ;;
            *)
                echo -e "${RED}Invalid option: -$OPTARG${NC}"
                exit 1
                ;;
        esac
    done
}

# Function to deploy PG Fork with or without PIN check based on flag
deploy_pg_fork_menu() {
    deploy_pg_fork "$skip_pin_check"
}

# Main Execution Flow
parse_args "$@"
deploy_pg_fork_menu


info() {
    echo -e "${BOLD}${GOLD}[INFO] $1${NC}"
}

warn() {
    echo -e "${BOLD}${RED}[WARN] $1${NC}"
}

error() {
    echo -e "${BOLD}${RED}[ERROR] $1${NC}"
}

# Function to execute the adduser.sh script with better control
execute_adduser_script() {
    local config_file="/pg/config/username.cfg"
    local adduser_script_url="https://raw.githubusercontent.com/plexguide/Installer/refs/heads/v11/adduser.sh"
    local tmp_script="/tmp/adduser_tmp.sh"

    # Check if the config file exists and contains the word "username"
    if [[ -f "$config_file" ]] && grep -q "username" "$config_file"; then
#        echo "Existing user configuration found. Skipping user setup."
        return 0
    fi

    echo "Downloading the adduser script from URL..."

    # Download the script to a temporary file
    if curl -sL "$adduser_script_url" -o "$tmp_script"; then
        echo "Download successful."

        # Make sure the script is executable
        chmod +x "$tmp_script"

        # Execute the script
        if bash "$tmp_script"; then
            echo "User setup completed successfully."
        else
            echo "Error: Failed to execute the adduser script."
            exit 1
        fi

        # Remove the temporary script
        rm -f "$tmp_script"
    else
        echo "Error: Failed to download the adduser script. Please check your internet connection and try again."
        exit 1
    fi
}

# Function to create symbolic links for command scripts
create_command_symlinks() {
#    info "Creating command symlinks..."

    # Define an associative array with command names as keys and script paths as values
    declare -A commands=(
        ["plexguide"]="/pg/scripts/menu.sh"
        ["pg"]="/pg/scripts/menu.sh"
        ["pgdev"]="/pg/installer/install_dev.sh"
        ["pgbeta"]="/pg/installer/install_beta.sh"
        ["pgfork"]="/pg/installer/install_fork.sh"
        ["pgstable"]="/pg/installer/install_stable.sh"
        ["pgreinstall"]="/pgreinstall/pgreinstall.sh"
    )

    # Loop over the associative array to create symbolic links and set executable permissions
    for cmd in "${!commands[@]}"; do
        # Create the symbolic link with force option to overwrite if it exists
        sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"

        # Set ownership to 1000:1000
        sudo chown 1000:1000 "/usr/local/bin/$cmd"

        # Set the executable permission to 755 (read and execute for everyone)
        sudo chmod 755 "/usr/local/bin/$cmd"
        
#        info "Created symlink: $cmd -> ${commands[$cmd]}"
    done

#    info "Command symlinks created successfully."
}

# Function to ensure all created commands are 1000:1000 and executable
ensure_command_permissions() {
#    info "Ensuring correct permissions for all created commands..."

    local commands=("plexguide" "pg" "pgdev" "pgbeta" "pgfork" "pgstable" "pgreinstall")

    for cmd in "${commands[@]}"; do
        if [[ -L "/usr/local/bin/$cmd" ]]; then
            sudo chown 1000:1000 "/usr/local/bin/$cmd"
            sudo chmod 755 "/usr/local/bin/$cmd"
#            info "Set permissions for $cmd: owner 1000:1000, mode 755"
        else
            warn "Command $cmd not found or not a symlink in /usr/local/bin"
        fi
    done

#    info "Permissions check and update completed."
}

# Function to update permissions for /pg directory
update_pg_permissions() {
#    info "Updating permissions for /pg directory..."
    if [[ -d "/pg" ]]; then
        sudo chown -R 1000:1000 /pg
        sudo find /pg -type d -exec chmod 755 {} +
        sudo find /pg -type f -exec chmod 644 {} +
        sudo chmod +x /pg/scripts/*.sh /pg/installer/*.sh /pgreinstall/*.sh 2>/dev/null
#        info "Permissions updated for /pg directory"
    else
        warn "/pg directory not found"
    fi
}

# Main script execution
execute_adduser_script
create_command_symlinks
ensure_command_permissions
update_pg_permissions

# info "Setup complete. You can now use the pginstall command to run the installer."