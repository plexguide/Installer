#!/bin/bash

# ANSI color codes
BRIGHT_RED="\033[1;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
LIGHT_GREEN="\033[1;32m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
BOLD="\033[1m"
NC="\033[0m"  # No color

# Clear the screen at the start
clear

# Display the header
echo -e "${BRIGHT_RED}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${BRIGHT_RED}${BOLD}Visit github.com/plexguide/PlexGuide.com | plexguide.com${NC}"
echo -e "${BRIGHT_RED}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""  # Space for separation

# Display information and commands
echo -e "${BOLD}Commands:${NC}"
echo -e "[${BRIGHT_RED}1${NC}] plexguide   |  ${BOLD}Deploy PlexGuide${NC}"
echo -e "[${ORANGE}2${NC}] pg          |  ${BOLD}Deploy PlexGuide${NC}"
echo -e "[${YELLOW}3${NC}] pgalpha     |  ${BOLD}Install Latest Alpha Build${NC}"
echo -e "[${LIGHT_GREEN}4${NC}] pgbeta      |  ${BOLD}Install Latest Beta Build${NC}"
echo -e "[${CYAN}5${NC}] pgfork      |  ${BOLD}Deploy PGFork${NC}"
echo -e "[${PURPLE}6${NC}] pginstall   |  ${BOLD}Access the Installer Menu (Helps Repairs)${NC}"
echo ""  # Space before exiting

# Exit the script
exit 0