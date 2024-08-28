#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
LIGHT_BLUE="\033[1;34m"
NC="\033[0m" # No color

prepare_tmp_directory() {
    local tmp_dir="/pg/tmp"
    
    # Create the /pg/tmp directory if it doesn't exist
    if [[ ! -d "$tmp_dir" ]]; then
        mkdir -p "$tmp_dir"
    fi
}

# Function to display the interface
display_interface() {
    clear
    echo -e "${CYAN}PG Edition Selection Interface${NC}"
    echo -e "Note: Stable Edition will be Released When Ready."
    echo ""  # Space below the note
    echo -e "[${RED}A${NC}] PG Alpha"
    echo -e "[${PURPLE}B${NC}] PG Beta"
    echo -e "[${LIGHT_BLUE}F${NC}] PG Fork"
    echo -e "[Z] Exit"
    echo ""
}

# Function to validate the user's choice
validate_choice() {
    local choice="$1"
    case ${choice,,} in
        a)
            echo "Selected PG Alpha." && echo ""
            run_install_script "https://raw.githubusercontent.com/plexguide/PlexGuide.com/v11/mods/scripts/install_alpha.sh"
            exit 0
            ;;
        b)
            echo "Selected PG Beta." && echo ""
            run_install_script "https://raw.githubusercontent.com/plexguide/PlexGuide.com/v11/mods/scripts/install_beta.sh"
            exit 0
            ;;
        f)
            echo "Selected PG Fork." && echo ""
            run_install_script "https://raw.githubusercontent.com/plexguide/PlexGuide.com/v11/mods/scripts/install_fork.sh"
            exit 0
            ;;
        z)
            echo "Exiting the selection interface."
            echo ""
            exit 0
            ;;
        *)
            echo "Invalid input. Please try again."
            ;;
    esac
}

# Function to download and run the selected installation script
run_install_script() {
    local script_url="$1"
    local tmp_dir="/pg/tmp"
    local script_file="$tmp_dir/install_script.sh"
    local random_pin=$(printf "%04d" $((RANDOM % 10000)))

    # Prepare the /pg/tmp directory
    prepare_tmp_directory

    while true; do
        read -p "$(echo -e "Type [${RED}${random_pin}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" response
        if [[ "$response" == "$random_pin" ]]; then
            echo "Downloading the installation script..."
            curl -sL "$script_url" -o "$script_file"
            
            # Check if the script was downloaded successfully
            if [[ -f "$script_file" ]]; then
                echo "Setting execute permissions and running the installation script..."
                chmod +x "$script_file"
                bash "$script_file"
                exit 0
            else
                echo "Failed to download the installation script. Please check your internet connection and try again."
                exit 1
            fi
        elif [[ "${response,,}" == "z" ]]; then
            echo "Installation canceled."
            exit 0
        else
            echo "Invalid input. Please try again."
        fi
    done
}

# Main loop to display the interface and handle user input
while true; do
    display_interface
    read -p "Enter your choice: " user_choice
    validate_choice "$user_choice"
    
    # Direct exit if 'z' or 'Z' is chosen
    if [[ "${user_choice,,}" == "z" ]]; then
        exit 0
    fi
done
