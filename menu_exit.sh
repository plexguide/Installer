#!/bin/bash

# ANSI color codes
BRIGHT_RED="\033[1;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
LIGHT_GREEN="\033[1;32m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Display information and commands
echo "Visit github.com/plexguide/PlexGuide.com or plexguide.com"
echo ""  # Space for separation
echo "Commands:"
echo -e "[${BRIGHT_RED}1${NC}] plexguide   |  Deploy PlexGuide"
echo -e "[${ORANGE}2${NC}] pg          |  Deploy PlexGuide"
echo -e "[${YELLOW}3${NC}] pgalpha     |  Install Latest Alpha Build"
echo -e "[${LIGHT_GREEN}4${NC}] pgbeta      |  Install Latest Beta Build"
echo -e "[${CYAN}5${NC}] pgfork      |  Deploy PGFork"
echo -e "[${PURPLE}6${NC}] pginstall   |  Access the Installer Menu (Helps Repairs)"  # New command for Installer Menu
echo ""  # Space before exiting

# Exit the script
exit 0
