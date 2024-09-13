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

# Clear the screen at the start
clear

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
echo -e "[${BRIGHT_BLUE}7${NC}] pginstall   |  Access the Installer Menu (Helps Repairs)"
echo ""  # Space before exiting

# Exit the script
exit 0