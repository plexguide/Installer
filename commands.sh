#!/bin/bash

# Function to create symbolic links for command scripts
create_command_symlinks() {
    echo "Creating command symlinks..."

    # Define an associative array with command names as keys and script paths as values
    declare -A commands=(
        ["plexguide"]="/pg/scripts/menu.sh"
        ["pg"]="/pg/scripts/menu.sh"
        ["pgalpha"]="/pg/installer/support.sh alpha"
        ["pgbeta"]="/pg/installer/support.sh beta"
        ["pgfork"]="/pg/installer/install_fork.sh"
    )

    # Loop over the associative array to create symbolic links and set executable permissions
    for cmd in "${!commands[@]}"; do
        # Handle pgalpha and pgbeta as wrappers to call support.sh with arguments
        if [[ "$cmd" == "pgalpha" || "$cmd" == "pgbeta" ]]; then
            cat << EOF | sudo tee "/usr/local/bin/$cmd" > /dev/null
#!/bin/bash
${commands[$cmd]}
EOF
        else
            # Directly create the symbolic link for other commands
            sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"
        fi

        # Set ownership and permissions for the command
        sudo chown 1000:1000 "/usr/local/bin/$cmd"
        sudo chmod 755 "/usr/local/bin/$cmd"
    done

    echo "Command symlinks created successfully."
}

# Function to set up the pginstall command
setup_pginstall_command() {
    echo "Setting up pginstall command..."

    # Define the URL of the install script
    local install_script_url="https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh"
    local tmp_dir="/pg/tmp"
    local tmp_script="$tmp_dir/install_menu_tmp.sh"

    # Ensure the temporary directory exists
    sudo mkdir -p "$tmp_dir"

    # Write the pginstall script to download and execute the install script
    cat << EOF | sudo tee /usr/local/bin/pginstall > /dev/null
#!/bin/bash
echo "Downloading and executing the PG installer..."
curl -sL "$install_script_url" -o "$tmp_script"
chmod +x "$tmp_script"
bash "$tmp_script"
EOF

    # Set ownership and permissions for the pginstall script
    sudo chown 1000:1000 /usr/local/bin/pginstall
    sudo chmod 755 /usr/local/bin/pginstall

    echo "pginstall command setup complete. You can now use the pginstall command to run the installer."
}

# Main script execution
create_command_symlinks
setup_pginstall_command

echo "Setup complete. You can now use the pginstall command to run the installer."