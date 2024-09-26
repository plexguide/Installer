#!/bin/bash

# Path to the configuration file
CONFIG_FILE="/pg/config/pgfork.cfg"
CONFIG_VERSION="/pg/config/config.cfg"
COMMANDS_SCRIPT="/pg/installer/commands.sh"

# ANSI color codes
LIGHT_RED="\033[1;31m"
LIGHT_YELLOW="\033[1;33m"
LIGHT_GREEN="\033[1;32m"
LIGHT_BLUE="\033[1;34m"
PURPLE="\033[0;35m"
HOT_PINK="\033[1;35m"
NC="\033[0m" # No color

# Default values
user="plexguide"
repo="plexguide.com"
branch="v11"

# Function to validate GitHub repository and branch
validate_github_repo_and_branch() {
    local api_url="https://api.github.com/repos/${user}/${repo}/branches/${branch}"
    if curl --output /dev/null --silent --head --fail "$api_url"; then
        return 0
    else
        return 1
    fi
}

# Function to parse command-line arguments
parse_args() {
    skip_pin_check=false
    while getopts "n" opt; do
        case ${opt} in
            n)
                skip_pin_check=true
                ;;
            *)
                echo -e "${RED}Invalid option: -$OPTARG${NC}"
                exit 1
                ;;
        esac
    done
}

# Function to deploy PG Fork, bypassing PIN check if -n flag is passed
deploy_pg_fork() {
    if [[ "$skip_pin_check" == "true" ]]; then
        # Skip the PIN check and deploy immediately
        echo "Skipping PIN check and proceeding with deployment..."

        echo "Validating repository details..."
        if validate_github_repo_and_branch; then
            echo ""
            echo "Repository details are valid. Proceeding with deployment..."
            create_directories
            download_repository
            move_folders
            set_config_version  # Call set_config_version here
            create_command_symlinks
            show_exit
            exit 0
        else
            echo ""
            echo "Invalid repository details. The user, repo, and/or branch is not valid."
            echo "Please update the information using the menu options."
            echo "Press [ENTER] to acknowledge and return to the menu."
            read -p ""
            return
        fi
    else
        # PIN verification for normal flow
        yes_code=$(printf "%04d" $((RANDOM % 10000)))
        no_code=$(printf "%04d" $((RANDOM % 10000)))
        echo "" && echo "You have chosen to deploy the PG Fork."
        while true; do
            echo ""
            echo -e "To proceed, enter this PIN: ${BOLD}${HOT_PINK}${yes_code}${NC}"
            echo -e "To cancel, enter this PIN: ${BOLD}${LIGHT_GREEN}${no_code}${NC}"
            
            echo && read -p "Enter PIN > " response

            if [[ "$response" == "$yes_code" ]]; then
                echo "Validating repository details..."
                if validate_github_repo_and_branch; then
                    echo ""
                    echo "Repository details are valid. Proceeding with deployment..."
                    create_directories
                    download_repository
                    move_folders
                    set_config_version  # Call set_config_version here
                    create_command_symlinks
                    show_exit
                    exit 0
                else
                    echo ""
                    echo "Invalid repository details. The user, repo, and/or branch is not valid."
                    echo "Please update the information using the menu options."
                    echo "Press [ENTER] to acknowledge and return to the menu."
                    read -p ""
                    return
                fi
            elif [[ "$response" == "$no_code" ]]; then
                echo "Deployment canceled."
                break
            else
                echo && echo "Invalid input. Please try again."
            fi
        done
    fi
}

# Ensure the required directories exist, etc. (unchanged parts of the script)
# Call parse_args and deploy_pg_fork in the script execution flow

# Main Execution Flow
parse_args "$@"
deploy_pg_fork
