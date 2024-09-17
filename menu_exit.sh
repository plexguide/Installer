#!/bin/bash

# ANSI color codes
BRIGHT_RED="\033[1;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
LIGHT_GREEN="\033[1;32m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
BOLD="\033[1m"
BRIGHT_BLUE="\033[1;34m"
BRIGHT_MAGENTA="\033[1;35m"
NC="\033[0m"  # No color

# Function to set up PG executables and their permissions
setup_pg_executables() {
    local executables=(
        "/usr/local/bin/pg"
        "/usr/local/bin/plexguide"
        "/usr/local/bin/pgstable"
        "/usr/local/bin/pgbeta"
        "/usr/local/bin/pgdev"
        "/usr/local/bin/pgfork"
        "/usr/local/bin/pgreinstall"
    )

    echo "Setting up PG executables..."
    for executable in "${executables[@]}"; do
        if [[ -L "$executable" ]]; then
            sudo chown 1000:1000 "$executable"
            sudo chmod 755 "$executable"
            echo "Updated symlink: $executable"
        else
            echo "Warning: $executable not found or not a symlink"
        fi
    done
}

# Function to update permissions for /pg directory
update_pg_permissions() {
    echo "Updating permissions for /pg directory..."
    if [[ -d "/pg" ]]; then
        sudo chown -R 1000:1000 /pg
        sudo find /pg -type d -exec chmod 755 {} +
        sudo find /pg -type f -exec chmod 644 {} +
        sudo chmod +x /pg/scripts/*.sh /pg/installer/*.sh /pgreinstall/*.sh 2>/dev/null
        echo "Permissions updated for /pg directory"
    else
        echo "Warning: /pg directory not found"
    fi
}

# Main script execution
clear

# Run setup functions
setup_pg_executables
update_pg_permissions

# Display the header
echo -e "${BRIGHT_RED}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${BRIGHT_RED}${BOLD}Visit plexguide.com | github.com/plexguide/PlexGuide.com${NC}"
echo -e "${BRIGHT_RED}${BOLD}════════════════════════════════════════════════════════${NC}"
echo ""  # Space for separation

# Display information and commands
echo -e "${BOLD}Commands:${NC}"
echo -e "[${BRIGHT_RED}1${NC}] plexguide   |  Deploy PlexGuide"
echo -e "[${ORANGE}2${NC}] pg          |  Deploy PlexGuide"
echo -e "[${LIGHT_GREEN}3${NC}] pgstable    |  Install Latest Stable Build"
echo -e "[${YELLOW}4${NC}] pgbeta      |  Install Latest Beta Build"
echo -e "[${BRIGHT_MAGENTA}5${NC}] pgdev       |  Install Latest Dev Build"
echo -e "[${CYAN}6${NC}] pgfork      |  Fork PlexGuide"
echo -e "[${BRIGHT_BLUE}7${NC}] pgreinstall |  To Reinstall PlexGuide (Helps /w Repairs)" 
echo ""  # Space before exiting

echo "Setup and permission updates completed. Please run PlexGuide commands as the non-root user."

# Exit the script
exit 0