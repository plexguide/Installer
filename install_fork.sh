#!/bin/bash

# Path to the configuration file
CONFIG_FILE="/pg/config/pgfork.cfg"
COMMANDS_SCRIPT="/pg/installer/commands.sh"

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
NC="\033[0m" # No color

# Default values
user="Admin9705"
repo="PlexGuide.com"
branch="v11"

# Check if the configuration file exists, if not, create it
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Creating config file at $CONFIG_FILE"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
    echo "user=\"$user\"" > "$CONFIG_FILE"
    echo "repo=\"$repo\"" >> "$CONFIG_FILE"
    echo "branch=\"$branch\"" >> "$CONFIG_FILE"
else
    # Source the configuration file to load existing values
    source "$CONFIG_FILE"
fi

# Function to ensure commands.sh exists and is executable
ensure_commands_script() {
    if [[ ! -f "$COMMANDS_SCRIPT" ]]; then
        echo "commands.sh not found. Downloading from GitHub..."
        mkdir -p "$(dirname "$COMMANDS_SCRIPT")"
        curl -o "$COMMANDS_SCRIPT" https://raw.githubusercontent.com/plexguide/Installer/v11/commands.sh
        chmod +x "$COMMANDS_SCRIPT"
        chown 1000:1000 "$COMMANDS_SCRIPT"
    fi
}

# Function to create command symlinks
create_command_symlinks() {
    ensure_commands_script
    source "$COMMANDS_SCRIPT"
    create_command_symlinks
}

# Function to create directories with the correct permissions
create_directories() {
    echo "Creating necessary directories..."

    directories=(
        "/pg/config"
        "/pg/scripts"
        "/pg/apps"
        "/pg/stage"
        "/pg/installer"
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

    # Download the repository using the user, repo, and branch variables
    echo "Downloading repository from ${user}/${repo} on branch ${branch}..."
    git clone -b "$branch" "https://github.com/${user}/${repo}.git" /pg/stage/

    if [[ $? -eq 0 ]]; then
        echo "Repository successfully downloaded to /pg/stage/."
    else
        echo "Failed to download the repository. Please check your network connection and repository details."
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

# Function to update the user name
update_user_name() {
    read -p "Enter the new user name: " new_user
    if [[ -n "$new_user" ]]; then
        user="$new_user"
        echo "user=\"$user\"" > "$CONFIG_FILE"
        echo "repo=\"$repo\"" >> "$CONFIG_FILE"
        echo "branch=\"$branch\"" >> "$CONFIG_FILE"
        echo -e "\nUser name updated to: $user"
        echo -e "\nYour changes have been recorded. Press [ENTER] to acknowledge."
        read -p ""
    else
        echo "User name cannot be empty. No changes made."
    fi
}

# Function to update the repo name
update_repo_name() {
    read -p "Enter the new repo name: " new_repo
    if [[ -n "$new_repo" ]]; then
        repo="$new_repo"
        echo "user=\"$user\"" > "$CONFIG_FILE"
        echo "repo=\"$repo\"" >> "$CONFIG_FILE"
        echo "branch=\"$branch\"" >> "$CONFIG_FILE"
        echo -e "\nRepo name updated to: $repo"
        echo -e "\nYour changes have been recorded. Press [ENTER] to acknowledge."
        read -p ""
    else
        echo "Repo name cannot be empty. No changes made."
    fi
}

# Function to update the branch name
update_branch_name() {
    read -p "Enter the new branch name: " new_branch
    if [[ -n "$new_branch" ]]; then
        branch="$new_branch"
        echo "user=\"$user\"" > "$CONFIG_FILE"
        echo "repo=\"$repo\"" >> "$CONFIG_FILE"
        echo "branch=\"$branch\"" >> "$CONFIG_FILE"
        echo -e "\nBranch name updated to: $branch"
        echo -e "\nYour changes have been recorded. Press [ENTER] to acknowledge."
        read -p ""
    else
        echo "Branch name cannot be empty. No changes made."
    fi
}

# Function to validate GitHub repository and branch
validate_github_repo_and_branch() {
    local api_url="https://api.github.com/repos/${user}/${repo}/branches/${branch}"
    if curl --output /dev/null --silent --head --fail "$api_url"; then
        return 0
    else
        return 1
    fi
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
            echo "Validating repository details..."
            if validate_github_repo_and_branch; then
                echo "Repository details are valid. Proceeding with deployment..."
                create_directories
                download_repository
                move_scripts
                set_config_version
                create_command_symlinks
                echo "Deployment completed successfully."
                echo "Press [ENTER] to exit."
                read -p ""
                show_exit
                exit 0
            else
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
            echo "Invalid input. Please try again."
        fi
    done
}

show_exit() {
    bash /pg/installer/menu_exit.sh
}

# Display the PG Fork menu
display_pgfork_menu() {
    while true; do
        clear
        echo -e "${PURPLE}PG Fork - OG Style${NC}"
        echo "User: $user | Repo: $repo | Branch: $branch"
        echo ""
        echo -e "[${RED}D${NC}] Deploy PG Fork"
        echo -e "[${RED}U${NC}] Update User Name"
        echo -e "[${RED}R${NC}] Update Repo Name"
        echo -e "[${RED}B${NC}] Update Branch Name"
        echo -e "[${GREEN}Z${NC}] Exit"
        echo ""
        read -p "Enter a choice: " choice

        case ${choice,,} in
            d)
                deploy_pg_fork
                ;;
            u)
                update_user_name
                ;;
            r)
                update_repo_name
                ;;
            b)
                update_branch_name
                ;;
            z)
                show_exit
                exit 0
                ;;
            *)
                echo "Invalid input. Please try again."
                ;;
        esac
    done
}

menu_commands() {
    echo "Returning to the main menu..."
    bash /pg/installer/menu_commands.sh
}

# Ensure commands.sh exists and create symlinks at the start
ensure_commands_script
create_command_symlinks

# Start the PG Fork menu
display_pgfork_menu