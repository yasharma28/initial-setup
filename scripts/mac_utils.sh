#!/bin/bash
set -euo pipefail

#######################################
# Error Codes
# 0   - Success
# 1   - General Error
# 150 - Failed to get AWS_ACCESS_KEY_ID
# 151 - Failed to get AWS_SECRET_ACCESS_KEY
# 152 - Failed to get AWS_DEFAULT_REGION
# 160 - Failed to clean Homebrew
# 161 - Failed to install packages from Brewfile
# 162 - Failed to save Homebrew packages
# 163 - Failed to update Homebrew
# 164 - Failed to upgrade Homebrew packages
# 165 - Failed to update gcloud components
# 180 - Failed to prune Docker system
# 190 - Invalid Argument
# 191 - Unexpected Termination
#######################################

# Define error code constants for better readability
ERROR_SUCCESS=0
ERROR_GENERAL=1

# AWS-related errors (150-159)
ERROR_AWS_ACCESS_KEY=150
ERROR_AWS_SECRET_KEY=151
ERROR_AWS_REGION=152

# Homebrew and other package-related errors (160-179)
ERROR_CLEAN_HOMEBREW=160
ERROR_INSTALL_PACKAGES=161
ERROR_SAVE_HOMEBREW=162
ERROR_UPDATE_HOMEBREW=163
ERROR_UPGRADE_HOMEBREW=164
ERROR_UPDATE_GCLOUD=165

# Docker-related errors (180-189)
ERROR_PRUNE_DOCKER=180

# Other errors (190-199)
ERROR_INVALID_ARG=190
ERROR_UNEXPECTED=191

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log levels
LOG_LEVELS=("DEBUG" "INFO" "WARN" "ERROR")
LOG_LEVEL="INFO"
LOG_FILE=""

#######################################
# Print usage information.
# Outputs:
#   Displays script usage information.
#######################################
usage() {
    cat << EOF
${0##*/} [OPTIONS]

NAME:
    utils.sh - Utility functions for setup and program management.

DESCRIPTION:
    A set of utility functions to assist in setup and maintenance of various programs.

OPTIONS:
    -a, --all-homebrew                Run homebrew update, upgrade, and save packages.
    --aws-profile AWS_PROFILE         Set environment variables from the specified AWS profile.
    -d, --docker-cleanup              Cleanup all Docker-related data.
    -h, --help                        Display this help message and exit.
    -i, --install-homebrew-packages   Install packages from the specified file (default: ~/.brew/Brewfile).
    -o, --other-packages-update       Update packages not installed via Homebrew.
    -s, --save-homebrew-packages      Save the list of installed Homebrew packages.
    -u, --update-homebrew-packages    Update and upgrade Homebrew packages.
    --log-level LEVEL                 Set the logging level (DEBUG, INFO, WARN, ERROR).
    --log-file FILE                   Set the log file to save logs in addition to displaying them on the CLI.
EOF
}

#######################################
# Handle exit codes with corresponding error messages.
# Arguments:
#   $1: Exit code.
#   $2: Additional message to display with the error (optional).
# Outputs:
#   Logs an error message and exits the script with the given exit code.
#######################################
handle_exit_code() {
    local exit_code=$1
    local additional_msg="${2:-}"

    case $exit_code in
        "$ERROR_SUCCESS")
            log "INFO" "Success: The operation completed successfully. ${additional_msg}"
            ;;
        "$ERROR_GENERAL")
            log "ERROR" "General Error: An unspecified error has occurred. ${additional_msg}"
            ;;
        "$ERROR_AWS_ACCESS_KEY")
            log "ERROR" "Error Code ${ERROR_AWS_ACCESS_KEY}: Failed to get AWS_ACCESS_KEY_ID. ${additional_msg}"
            ;;
        "$ERROR_AWS_SECRET_KEY")
            log "ERROR" "Error Code ${ERROR_AWS_SECRET_KEY}: Failed to get AWS_SECRET_ACCESS_KEY. ${additional_msg}"
            ;;
        "$ERROR_AWS_REGION")
            log "ERROR" "Error Code ${ERROR_AWS_REGION}: Failed to get AWS_DEFAULT_REGION. ${additional_msg}"
            ;;
        "$ERROR_CLEAN_HOMEBREW")
            log "ERROR" "Error Code ${ERROR_CLEAN_HOMEBREW}: Failed to clean Homebrew. ${additional_msg}"
            ;;
        "$ERROR_INSTALL_PACKAGES")
            log "ERROR" "Error Code ${ERROR_INSTALL_PACKAGES}: Failed to install packages from Brewfile. ${additional_msg}"
            ;;
        "$ERROR_SAVE_HOMEBREW")
            log "ERROR" "Error Code ${ERROR_SAVE_HOMEBREW}: Failed to save Homebrew packages. ${additional_msg}"
            ;;
        "$ERROR_UPDATE_HOMEBREW")
            log "ERROR" "Error Code ${ERROR_UPDATE_HOMEBREW}: Failed to update Homebrew. ${additional_msg}"
            ;;
        "$ERROR_UPGRADE_HOMEBREW")
            log "ERROR" "Error Code ${ERROR_UPGRADE_HOMEBREW}: Failed to upgrade Homebrew packages. ${additional_msg}"
            ;;
        "$ERROR_UPDATE_GCLOUD")
            log "ERROR" "Error Code ${ERROR_UPDATE_GCLOUD}: Failed to update gcloud components. ${additional_msg}"
            ;;
        "$ERROR_PRUNE_DOCKER")
            log "ERROR" "Error Code ${ERROR_PRUNE_DOCKER}: Failed to prune Docker system. ${additional_msg}"
            ;;
        "$ERROR_INVALID_ARG")
            log "ERROR" "Error Code ${ERROR_INVALID_ARG}: Invalid argument provided. ${additional_msg}"
            ;;
        "$ERROR_UNEXPECTED")
            log "ERROR" "Error Code ${ERROR_UNEXPECTED}: Script terminated unexpectedly. ${additional_msg}"
            ;;
        *)
            log "ERROR" "Unknown Error Code ${exit_code}: An unknown error has occurred. ${additional_msg}"
            ;;
    esac

    exit "$exit_code"
}

#######################################
# Logging function.
# Arguments:
#   $1: Log level (DEBUG, INFO, WARN, ERROR).
#   $2: Message to log.
# Outputs:
#   Logs the message to STDERR or STDOUT with a timestamp and color-coded log level.
#######################################
log() {
    local log_level=$1
    shift
    local log_level_index
    log_level_index=$(printf "%s\n" "${LOG_LEVELS[@]}" | grep -n "^${log_level}$" | cut -d: -f1)
    local current_level_index
    current_level_index=$(printf "%s\n" "${LOG_LEVELS[@]}" | grep -n "^${LOG_LEVEL}$" | cut -d: -f1)

    if [ "$log_level_index" -ge "$current_level_index" ]; then
        local color=""
        case "$log_level" in
            DEBUG) color="$BLUE" ;;
            INFO) color="$GREEN" ;;
            WARN) color="$YELLOW" ;;
            ERROR) color="$RED" ;;
            *) color="$NC" ;;
        esac
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local message_plain="[$timestamp] $log_level: $*"
        local message_colored="[$timestamp] ${color}${log_level}${NC}: $*"

        if [ "$log_level" = "ERROR" ]; then
            echo -e "$message_colored" >&2
        else
            echo -e "$message_colored"
        fi

        if [ -n "$LOG_FILE" ]; then
            echo "$message_plain" >> "$LOG_FILE" || true
        fi
    fi
}

#######################################
# Setup environment variables from AWS profile.
# Globals:
#   AWS_PROFILE
# Outputs:
#   Exports AWS environment variables.
#######################################
aws_env_setup() {
    log "INFO" "Setting up AWS environment variables for profile '${AWS_PROFILE}'"
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "${AWS_PROFILE}") || {
        handle_exit_code $ERROR_AWS_ACCESS_KEY "Failed to retrieve AWS_ACCESS_KEY_ID for profile '${AWS_PROFILE}'."
    }
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "${AWS_PROFILE}") || {
        handle_exit_code $ERROR_AWS_SECRET_KEY "Failed to retrieve AWS_SECRET_ACCESS_KEY for profile '${AWS_PROFILE}'."
    }
    AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile "${AWS_PROFILE}") || true
    AWS_SECURITY_TOKEN=$(aws configure get aws_security_token --profile "${AWS_PROFILE}") || true
    AWS_DEFAULT_REGION=$(aws configure get region --profile "${AWS_PROFILE}") || {
        handle_exit_code $ERROR_AWS_REGION "Failed to retrieve AWS_DEFAULT_REGION for profile '${AWS_PROFILE}'."
    }

    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export AWS_SESSION_TOKEN
    export AWS_SECURITY_TOKEN
    export AWS_DEFAULT_REGION

    log "INFO" "AWS environment variables for profile '${AWS_PROFILE}' exported successfully."
}

#######################################
# Cleanup Homebrew.
# Outputs:
#   Cleans Homebrew installations and cache.
#######################################
clean_homebrew() {
    log "INFO" "Cleaning Homebrew..."
    brew cleanup --prune=all || {
        handle_exit_code $ERROR_CLEAN_HOMEBREW "Homebrew cleanup failed."
    }
    log "INFO" "Homebrew cleaned successfully."
}

#######################################
# Cleanup Docker.
# Outputs:
#   Removes all Docker containers, images, and volumes.
#######################################
docker_cleanup() {
    log "INFO" "Cleaning Docker containers..."
    docker ps -aq | xargs -r docker stop || log "WARN" "Failed to stop some Docker containers."
    log "INFO" "Pruning Docker system..."
    docker system prune -a -f --volumes || {
        handle_exit_code $ERROR_PRUNE_DOCKER "Docker system prune failed."
    }
    log "INFO" "Docker cleaned successfully."
}

#######################################
# Install packages from a specified file.
# Globals:
#   FILE_NAME
# Outputs:
#   Installs packages listed in the specified file.
#######################################
install_packages() {
    log "INFO" "Installing packages from '${FILE_NAME}'..."
    brew bundle --no-lock --file="${FILE_NAME}" || {
        handle_exit_code $ERROR_INSTALL_PACKAGES "Installation from '${FILE_NAME}' failed."
    }
    log "INFO" "Packages installed successfully from '${FILE_NAME}'."
}

#######################################
# Update other packages not managed by Homebrew.
# Outputs:
#   Updates other non-Homebrew packages.
#######################################
other_opt_update() {
    log "INFO" "Updating non-Homebrew applications..."
    gcloud components update -q || {
        handle_exit_code $ERROR_UPDATE_GCLOUD "gcloud components update failed."
    }
    log "INFO" "Non-Homebrew applications updated successfully."
}

#######################################
# Save Homebrew installed packages to a file.
# Outputs:
#   Saves the list of Homebrew packages to ~/.brew/Brewfile.
#######################################
save_packages() {
    log "INFO" "Saving Homebrew packages to '${HOME}/.brew/Brewfile'..."
    mkdir -p "${HOME}/.brew/"
    brew bundle dump -f --file="${HOME}/.brew/Brewfile" || {
        handle_exit_code $ERROR_SAVE_HOMEBREW "Saving Homebrew packages failed."
    }
    log "INFO" "Homebrew packages saved successfully to '${HOME}/.brew/Brewfile'."
}

#######################################
# Update and upgrade Homebrew packages.
# Outputs:
#   Updates Homebrew and upgrades installed packages.
#######################################
update_homebrew_packages() {
    log "INFO" "Updating Homebrew..."
    brew update || {
        handle_exit_code $ERROR_UPDATE_HOMEBREW "Homebrew update failed."
    }
    log "INFO" "Upgrading Homebrew packages..."
    brew upgrade -g || {
        handle_exit_code $ERROR_UPGRADE_HOMEBREW "Homebrew upgrade failed."
    }
    log "INFO" "Homebrew updated and upgraded successfully."
}

#######################################
# Main function to process input options.
# Arguments:
#   Arguments passed to the script.
#######################################
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                handle_exit_code $ERROR_SUCCESS "Help displayed."
                ;;
            --all-homebrew|-a)
                update_homebrew_packages
                other_opt_update
                clean_homebrew
                save_packages
                shift
                ;;
            --aws-profile)
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    AWS_PROFILE="$2"
                    shift 2
                else
                    handle_exit_code $ERROR_INVALID_ARG "Missing value for '--aws-profile'."
                fi
                aws_env_setup
                ;;
            --docker-cleanup|-d)
                docker_cleanup
                shift
                ;;
            --install-homebrew-packages|-i)
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    FILE_NAME="$2"
                    shift 2
                else
                    FILE_NAME="${HOME}/.brew/Brewfile"
                    shift
                fi
                install_packages
                ;;
            --other-packages-update|-o)
                other_opt_update
                shift
                ;;
            --save-homebrew-packages|-s)
                save_packages
                shift
                ;;
            --update-homebrew-packages|-u)
                update_homebrew_packages
                shift
                ;;
            --log-level)
                if [[ -n "${2:-}" && " ${LOG_LEVELS[*]} " == *" $2 "* ]]; then
                    LOG_LEVEL="$2"
                    shift 2
                else
                    handle_exit_code $ERROR_INVALID_ARG "Invalid or missing value for '--log-level'."
                fi
                ;;
            --log-file)
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    LOG_FILE="$2"
                    shift 2
                else
                    handle_exit_code $ERROR_INVALID_ARG "Missing value for '--log-file'."
                fi
                ;;
            *)
                handle_exit_code $ERROR_INVALID_ARG "Invalid argument '$1'."
                ;;
        esac
    done
}

# Trap unexpected exits and handle them gracefully
trap 'handle_exit_code $ERROR_UNEXPECTED "Script terminated unexpectedly."' SIGINT SIGTERM

# Execute main function with all script arguments.
main "$@"
