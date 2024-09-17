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

setup_user() {
    info "Setting up user account..."
    local existing_user=$(id -nu 1000 2>/dev/null)
    if [ -n "$existing_user" ]; then
        info "Existing user found: $existing_user"
        usermod -aG sudo,video,docker "$existing_user"
        chsh -s /bin/bash "$existing_user"
        info "User $existing_user has been updated with necessary group permissions."
    else
        info "No user with UID 1000 found. Creating a new user."
        local username password
        while true; do
            read -rp "Enter username (lowercase letters and numbers only): " username
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
            read -s -rp "Enter password (min 8 characters): " password
            echo
            if [[ ${#password} -ge 8 ]]; then
                break
            else
                warn "Password must be at least 8 characters long."
            fi
        done
        if useradd -m -s /bin/bash -U "$username"; then
            echo "$username:$password" | chpasswd
            usermod -aG sudo,video,docker "$username"
            info "User $username has been created successfully."
        else
            error "Failed to create user $username."
        fi
    fi
    local final_user=$(id -nu 1000)
    info "Primary user account: $final_user"
}

# Call the setup_user function
setup_user