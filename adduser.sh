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

setup_pg_directory() {
    if [[ -d "/pg" ]]; then
        find /pg -type d -exec chmod 755 {} + 2>/dev/null
        find /pg -type f -exec chmod 644 {} + 2>/dev/null
        chown -R 1000:1000 /pg 2>/dev/null
    fi
}

check_existing_config() {
    if [[ -f "/pg/config/username.cfg" ]]; then
        if grep -q "username" "/pg/config/username.cfg"; then
            info "Existing configuration found in /pg/config/username.cfg. Skipping user setup."
            exit 0
        fi
    fi
}

validate_password() {
    local pass="$1"
    if [[ ${#pass} -lt 10 ]]; then
        return 1
    fi
    if ! [[ "$pass" =~ [0-9] ]]; then
        return 1
    fi
    return 0
}

remove_1000_user() {
    local existing_user=$(id -nu 1000 2>/dev/null)
    if [ -n "$existing_user" ]; then
        echo "" && warn "User with UID 1000 found: $existing_user"
        read -p "This user will be removed. Are you sure? (y/N): " confirm
        if [[ $confirm == [yY] ]]; then
            info "Removing user $existing_user..."
            pkill -u "$existing_user"  # Kill all processes owned by the user
            if userdel -r "$existing_user"; then
                info "User $existing_user has been removed successfully."
            else
                error "Failed to remove user $existing_user. Exiting."
                exit 1
            fi
        else
            error "User removal cancelled. Exiting."
            exit 1
        fi
    else
        info "No user with UID 1000 found. Proceeding with new user creation."
    fi
}

setup_user() {
    info "Setting up new user account..."
    local username password password_confirm
    while true; do
        read -rp "Enter username (lowercase letters and numbers only): " username
        if [[ "$username" =~ ^[a-z][a-z0-9]*$ ]]; then
            if ! id "$username" &>/dev/null; then
                break
            else
                warn "User $username already exists. Please choose a different username."
            fi
        else
            warn "Invalid username."
            warn "Lowercase letters and numbers only; starting with a letter."
        fi
    done
    while true; do
        while true; do
            read -s -rp "Enter password (min 10 characters and at least one number): " password
            echo
            if validate_password "$password"; then
                break
            else
                warn "Invalid Password!" 
                warn "Must be at least 10 characters long and contain at least one number."
            fi
        done
        read -s -rp "Confirm password: " password_confirm
        echo
        if [ "$password" = "$password_confirm" ]; then
            break
        else
            warn "Passwords do not match. Please try again."
        fi
    done
    if useradd -m -s /bin/bash -U -u 1000 "$username"; then
        echo "$username:$password" | chpasswd
        usermod -aG sudo,video,docker "$username"
        info "User $username has been created successfully with UID 1000."
        
        # Create config directory and file
        mkdir -p /pg/config
        echo "username=\"$username\"" > /pg/config/username.cfg
        chown 1000:1000 /pg/config/username.cfg
        chmod 744 /pg/config/username.cfg
        info "Configuration file created at /pg/config/username.cfg"
    else
        error "Failed to create user $username with UID 1000."
        exit 1
    fi
}

# Setup /pg directory permissions in the background
setup_pg_directory &

# Check for existing configuration
check_existing_config

# Main execution
remove_1000_user
setup_user

info "User setup complete. New primary user account: $(id -nu 1000)"