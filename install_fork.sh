#!/bin/bash

# Path to the configuration file
CONFIG_FILE="/pg/config/pgfork.cfg"

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
NC="\033[0m" # No color

# Default repo (user) and branch
repo="Admin9705"
branch="v11"

# Check if the configuration file exists, if not, create it
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Creating config file at $CONFIG_FILE"
    touch "$CONFIG_FILE"
    echo "repo=\"$repo\"" > "$CONFIG_FILE"
    echo "branch=\"$branch\"" >> "$CONFIG_FILE"
else
    # Source the configuration file to load existing values
    source "$CONFIG_FILE"
fi

# Function to create directories with the correct permissions
create_directories() {
    echo "Creating necessary directories..."

    directories=(
        "/pg/config"
        "/pg/scripts"
        "/pg/apps"
        "/pg/stage"
    )

    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo "Created $dir"
        else
            echo "$dir already exists"
        fi
        chown -R 1000:1000 "$dir"
        chmod -R +x "$dir"
    done
}

# Function to download and place files into /pg/stage/
download_repository() {
    echo "Preparing /pg/stage/ directory..."

    if [[ -d "/pg/stage/" ]]; then
        rm -rf /pg/stage/*
        rm -rf /pg/stage/.* 2>/dev/null || true
        echo "Cleared /pg/stage/ directory."
    fi

    # Download the repository using the repo and branch variables
    echo "Downloading repository from ${repo}'s fork on branch ${branch}..."
    git clone -b "$branch" https://github.com/"$repo"/PlexGuide.com.git /pg/stage/

    if [[ $? -eq 0 ]]; then
        echo "Repository successfully downloaded to /pg/stage/."
    else
        echo "Failed to download the repository. Please check your network connection."
        exit 1
    fi
}

# Function to move scripts from /pg/stage/mods/scripts to /pg/scripts/
move_scripts() {
    echo "Moving scripts from /pg/stage/mods/scripts to /pg/scripts/..."

    if [[ -d "/pg/stage/mods/scripts" ]]; then
        mv /pg/stage/mods/scripts/* /pg/scripts/

        if [[ $? -eq 0 ]]; then
            echo "Scripts successfully moved to /pg/scripts/."
        else
            echo "Failed to move scripts. Please check the file paths and permissions."
            exit 1
        fi
    else
        echo "Source directory /pg/stage/mods/scripts does not exist. No files to move."
        menu_commands
        exit 1
    fi
}

# Function to move apps from /pg/stage/mods/apps to /pg/apps/
move_apps() {
    echo "Clearing the /pg/apps/ directory..."

    if [[ -d "/pg/apps/" ]]; then
        rm -rf /pg/apps/*
        rm -rf /pg/apps/.* 2>/dev/null || true
        echo "Cleared /pg/apps/ directory."
    fi

    echo "Moving apps from /pg/stage/mods/apps to /pg/apps/..."

    if [[ -d "/pg/stage/mods/apps" ]]; then
        mv /pg/stage/mods/apps/* /pg/apps/

        if [[ $? -eq 0 ]]; then
            echo "Apps successfully moved to /pg/apps/."
        else
            echo "Failed to move apps. Please check the file paths and permissions."
            exit 1
        fi
    else
        echo "Source directory /pg/stage/mods/apps does not exist. No files to move."
        menu_commands
        exit 1
    fi
}

# Function to check and install Docker if not installed
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "\e[38;5;196mD\e[38;5;202mO\e[38;5;214mC\e[38;5;226mK\e[38;5;118mE\e[38;5;51mR \e[38;5;201mI\e[38;5;141mS \e[38;5;93mI\e[38;5;87mN\e[38;5;129mS\e[38;5;166mT\e[38;5;208mA\e[38;5;226mL\e[38;5;190mL\e[38;5;82mI\e[38;5;40mN\e[38;5;32mG\e[0m"
        sleep .5
        chmod +x /pg/scripts/docker.sh
        bash /pg/scripts/docker.sh
    fi
}

# Function to set or update the VERSION in the config file
set_config_version() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Creating config file at $CONFIG_FILE"
        touch "$CONFIG_FILE"
    fi

    if grep -q "^VERSION=" "$CONFIG_FILE"; then
        sed -i 's/^VERSION=.*/VERSION="PG Fork"/' "$CONFIG_FILE"
    else
        echo 'VERSION="PG Fork"' >> "$CONFIG_FILE"
    fi

    echo "VERSION has been set to PG Fork in $CONFIG_FILE"
}

# Display the PG Fork menu
display_pgfork_menu() {
    while true; do
        clear
        echo -e "${PURPLE}PG Fork - OG Style${NC}"
        echo "Repo: $repo | Branch: $branch"
        echo ""
        echo -e "[${RED}D${NC}] Deploy PG Fork"
        echo -e "[${RED}U${NC}] Update Repo Name"
        echo -e "[${RED}B${NC}] Update Branch Name"
        echo -e "[${GREEN}Z${NC}] Exit"
        echo ""
        read -p "Enter a choice: " choice

        case ${choice,,} in
            d)
                deploy_pg_fork
                ;;
            u)
                update_repo_name
                ;;
            b)
                update_branch_name
                ;;
            z)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid input. Please try again."
                ;;
        esac
    done
}

# Function to deploy the PG Fork
deploy_pg_fork() {
    # Generate random 4-digit PIN codes for "yes" and "no"
    yes_code=$(printf "%04d" $((RANDOM % 10000)))
    no_code=$(printf "%04d" $((RANDOM % 10000)))

    while true; do
        clear
        echo "You have chosen to deploy the PG Fork."
        echo ""
        echo -e "Type [${RED}${yes_code}${NC}] to proceed or [${GREEN}${no_code}${NC}] to cancel: "

        read -p "" response

        if [[ "$response" == "$yes_code" ]]; then
            echo "Deploying PG Fork..."
            create_directories
            download_repository
            move_scripts
            move_apps
            check_and_install_docker
            set_config_version
            menu_commands
            break
        elif [[ "$response" == "$no_code" ]]; then
            echo "Deployment canceled."
            break
        else
            echo "Invalid input. Please try again."
        fi
    done
}

# Function to update the repo name
update_repo_name() {
    read -p "Enter the new repo name (username): " new_repo
    if [[ -n "$new_repo" ]]; then
        repo="$new_repo"
        echo "repo=\"$repo\"" > "$CONFIG_FILE"
        echo "branch=\"$branch\"" >> "$CONFIG_FILE"
        echo "Repo name updated to: $repo"
    else
        echo "Invalid repo name. No changes made."
    fi
}

# Function to update the branch name
update_branch_name() {
    read -p "Enter the new branch name: " new_branch
    if [[ -n "$new_branch" ]]; then
        branch="$new_branch"
        echo "repo=\"$repo\"" > "$CONFIG_FILE"
        echo "branch=\"$branch\"" >> "$CONFIG_FILE"
        echo "Branch name updated to: $branch"
    else
        echo "Invalid branch name. No changes made."
    fi
}

menu_commands() {
    echo "Returning to the main menu..."
    bash /pg/scripts/menu_commands.sh
}

# Start the PG Fork menu
display_pgfork_menu
