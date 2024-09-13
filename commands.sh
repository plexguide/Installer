#!/bin/bash

# Function to create symbolic links for command scripts
create_command_symlinks() {
    echo "Creating command symlinks..."

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
create_command_symlinks
setup_pginstall_command

echo "Setup complete. You can now use the pginstall command to run the installer."