#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
ORANGE="\033[0;33m"
PURPLE="\033[0;35m"
LIGHT_BLUE="\033[1;34m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Display information and commands
echo "Visit github.com/plexguide/PlexGuide.com or plexguide.com"
echo ""  # Space for separation
echo "Commands:"
echo -e "[${ORANGE}1${NC}] plexguide   |  Deploy PlexGuide"
echo -e "[${ORANGE}2${NC}] pg          |  Deploy PlexGuide"
echo -e "[${RED}3${NC}] pgalpha     |  Install Latest Alpha Build"
echo -e "[${PURPLE}4${NC}] pgbeta      |  Install Latest Beta Build"
echo -e "[${LIGHT_BLUE}5${NC}] pgfork      |  Deploy PGFork"  # New command for PGFork in light blue
echo ""  # Space before exiting

# Exit the script
exit 0