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

# ... [keep all the existing functions: validate_github_user, validate_github_repo, validate_github_branch, create_directories, download_repository, move_scripts, set_config_version] ...

# Function to update the user name
update_user_name() {
    while true; do
        read -p "Enter the new user name: " new_user
        if [[ -n "$new_user" ]]; then
            if validate_github_user "$new_user"; then
                user="$new_user"
                echo "user=\"$user\"" > "$CONFIG_FILE"
                echo "repo=\"$repo\"" >> "$CONFIG_FILE"
                echo "branch=\"$branch\"" >> "$CONFIG_FILE"
                echo -e "\nUser name updated to: $user"
                echo -e "\nYour changes have been recorded. Press [ENTER] to acknowledge."
                read -p ""
                break
            else
                echo "Invalid GitHub user. Please try again."
            fi
        else
            echo "User name cannot be empty. No changes made."
            break
        fi
    done
}

# Function to update the repo name
update_repo_name() {
    while true; do
        read -p "Enter the new repo name: " new_repo
        if [[ -n "$new_repo" ]]; then
            if validate_github_repo "$user" "$new_repo"; then
                repo="$new_repo"
                echo "user=\"$user\"" > "$CONFIG_FILE"
                echo "repo=\"$repo\"" >> "$CONFIG_FILE"
                echo "branch=\"$branch\"" >> "$CONFIG_FILE"
                echo -e "\nRepo name updated to: $repo"
                echo -e "\nYour changes have been recorded. Press [ENTER] to acknowledge."
                read -p ""
                break
            else
                echo "Invalid GitHub repository. Please try again."
            fi
        else
            echo "Repo name cannot be empty. No changes made."
            break
        fi
    done
}

# Function to update the branch name
update_branch_name() {
    while true; do
        read -p "Enter the new branch name: " new_branch
        if [[ -n "$new_branch" ]]; then
            if validate_github_branch "$user" "$repo" "$new_branch"; then
                branch="$new_branch"
                echo "user=\"$user\"" > "$CONFIG_FILE"
                echo "repo=\"$repo\"" >> "$CONFIG_FILE"
                echo "branch=\"$branch\"" >> "$CONFIG_FILE"
                echo -e "\nBranch name updated to: $branch"
                echo -e "\nYour changes have been recorded. Press [ENTER] to acknowledge."
                read -p ""
                break
            else
                echo "Invalid branch name. Please try again."
            fi
        else
            echo "Branch name cannot be empty. No changes made."
            break
        fi
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
            echo "Validating repository details..."
            if validate_github_repo "$user" "$repo" && validate_github_branch "$user" "$repo" "$branch"; then
                echo "Repository details are valid. Proceeding with deployment..."
                create_directories
                download_repository
                move_scripts
                set_config_version
                create_command_symlinks
                menu_commands
                break
            else
                echo "Invalid repository details. Please update the user, repo, or branch name and try again."
                read -p "Press Enter to continue..."
            fi
        elif [[ "$response" == "$no_code" ]]; then
            echo "Deployment canceled."
            break
        else
            echo "Invalid input. Please try again."
        fi
    done
}

# ... [keep the existing display_pgfork_menu and menu_commands functions] ...

# Ensure commands.sh exists and create symlinks at the start
ensure_commands_script
create_command_symlinks

# Start the PG Fork menu
display_pgfork_menu