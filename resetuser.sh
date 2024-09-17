#!/bin/bash

info() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

error() {
    echo "[ERROR] $1"
}

remove_1000_user() {
    local existing_user=$(id -nu 1000 2>/dev/null)
    if [ -n "$existing_user" ]; then
        info "Removing existing user with UID 1000: $existing_user"
        pkill -u "$existing_user"  # Kill all processes owned by the user
        if userdel -r "$existing_user"; then
            info "User $existing_user has been removed successfully."
        else
            error "Failed to remove user $existing_user."
            exit 1
        fi
    else
        info "No user with UID 1000 found. Proceeding with setup."
    fi
}

setup_user() {
    info "Setting up new user account..."
    local username password
    while true; do
        read -rp "Enter username for new user (lowercase letters and numbers only): " username
        if [[ "$username" =~ ^[a-z][a-z0-9]*$ ]]; then
            if ! id "$username" &>/dev/null; then
                break
            else
                warn "User $username already exists. Please choose a different username."
            fi
        else
            warn "Invalid username. Please use only lowercase letters and numbers, starting with a letter."
        fi
    done
    while true; do
        read -s -rp "Enter password for new user (min 8 characters): " password
        echo
        if [[ ${#password} -ge 8 ]]; then
            break
        else
            warn "Password must be at least 8 characters long."
        fi
    done
    if useradd -m -s /bin/bash -U "$username" -u 1000; then
        echo "$username:$password" | chpasswd
        usermod -aG sudo,video,docker "$username"
        info "User $username has been created successfully with UID 1000."
    else
        error "Failed to create user $username."
        exit 1
    fi
}

# Main execution
remove_1000_user
setup_user

info "User setup complete. New primary user account: $(id -nu 1000)"