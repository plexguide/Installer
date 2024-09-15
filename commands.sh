#!/bin/bash

create_command_symlinks() {
    echo "Creating command symlinks..."
    
    commands=(
        "pgbeta"
        "pgfork"
        "pgdev"
        "pgstable"
    )

    for cmd in "${commands[@]}"; do
        target="/pg/scripts/menu.sh"
        symlink="/usr/local/bin/$cmd"

        if [[ -f "$target" ]]; then
            ln -sf "$target" "$symlink"
            echo "Created symlink: $symlink -> $target"
            
            # Set permissions and ownership only if the target exists
            if [[ -e "$symlink" ]]; then
                chown 1000:1000 "$symlink"
                chmod +x "$symlink"
            fi
        else
            echo "Target file for $cmd ($target) does not exist. Skipping symlink creation."
        fi
    done
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