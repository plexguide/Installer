#!/bin/bash

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
        # Create the symbolic link with force option to overwrite if it exists
        sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"

        # Set ownership to 1000:1000
        sudo chown 1000:1000 "/usr/local/bin/$cmd"

        # Set the executable permission to 755 (read and execute for everyone)
        sudo chmod 755 "/usr/local/bin/$cmd"
    done

    echo "Command symlinks created successfully."
}
