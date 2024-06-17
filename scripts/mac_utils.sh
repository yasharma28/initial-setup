#!/bin/bash

# Enable strict mode
set -euo pipefail

# Globals
AWS_PROFILE="default"
FILE_NAME="$HOME/.brew/Brewfile"
DRY_RUN=false

#######################################
# Print the usage information for the script.
# Outputs:
#   Output to STDOUT.
#######################################
usage() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

A set of utility functions to setup and run programs smoothly.

Options:
  -a, --all-homebrew                    Runs homebrew update, upgrade, and saves homebrew packages.
  --aws-profile PROFILE                 Set environment variables from AWS profile. Default is "default".
  -d, --docker-cleanup                  Cleanup all Docker related resources.
  -h, --help                            Display this help and exit.
  -i, --install-homebrew-packages FILE  Install packages for homebrew from a specified file. Default is "\$HOME/.brew/Brewfile".
  -s, --save-homebrew-packages          Save currently installed Homebrew packages to "\$HOME/.brew/Brewfile".
  -u, --update-homebrew-packages        Update Homebrew and upgrade installed packages.
  --dry-run                             Show what would be done without making any changes.

Examples:
  ${0##*/} --all-homebrew
  ${0##*/} --aws-profile myprofile
  ${0##*/} --install-homebrew-packages Brewfile
  ${0##*/} --docker-cleanup
  ${0##*/} --save-homebrew-packages
  ${0##*/} --update-homebrew-packages
  ${0##*/} --dry-run

Description:
  This script provides several utility functions to manage and automate tasks related to Homebrew, Docker, and AWS.
  - Use the --all-homebrew option to update, upgrade, and save Homebrew packages.
  - Use the --aws-profile option to set environment variables from a specific AWS profile.
  - Use the --docker-cleanup option to perform a complete cleanup of Docker resources.
  - Use the --install-homebrew-packages option to install Homebrew packages from a specified file.
  - Use the --save-homebrew-packages option to save the currently installed Homebrew packages to a Brewfile.
  - Use the --update-homebrew-packages option to update and upgrade Homebrew packages.
  - Use the --dry-run option to simulate the script actions without making any changes.

EOF
}

#######################################
# Print verbose message
# Globals:
#   DRY_RUN
# Arguments:
#   Message to print
# Outputs:
#   Output to STDOUT.
#######################################
verbose() {
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: $*"
    else
        echo "$*"
    fi
}

#######################################
# Setup environment variables from AWS profile.
# Globals:
#   AWS_PROFILE
# Outputs:
#   Exported environment variables.
#######################################
aws_env_setup() {
    verbose "Setting up AWS profile ${AWS_PROFILE}."
    if [ "$DRY_RUN" = false ]; then
        export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "${AWS_PROFILE}")
        export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "${AWS_PROFILE}")
        export AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile "${AWS_PROFILE}")
        export AWS_SECURITY_TOKEN=$(aws configure get aws_security_token --profile "${AWS_PROFILE}")
        export AWS_DEFAULT_REGION=$(aws configure get region --profile "${AWS_PROFILE}")
    fi
    verbose "${AWS_PROFILE} environment variables exported."
}

#######################################
# Cleanup homebrew by removing old versions of installed packages.
# Outputs:
#   Output to STDOUT.
#######################################
clean_homebrew() {
    verbose "Cleaning Homebrew..."
    if [ "$DRY_RUN" = false ]; then
        brew cleanup --prune=all
    fi
}

#######################################
# Perform complete cleanup of Docker.
# Outputs:
#   Output to STDOUT.
#######################################
docker_cleanup() {
    verbose "Cleaning up Docker..."
    if [ "$DRY_RUN" = false ]; then
        docker stop $(docker ps -aq) || true
        docker system prune -a -f
    fi
}

#######################################
# Install list of packages from a specified Brewfile.
# Globals:
#   FILE_NAME
# Outputs:
#   Output to STDOUT.
#######################################
install_packages() {
    verbose "Installing packages from ${FILE_NAME} file..."
    if [ "$DRY_RUN" = false ]; then
        brew bundle --no-lock --file="${FILE_NAME}"
    fi
}

#######################################
# Save list of installed packages to a Brewfile.
# Outputs:
#   Output to STDOUT and a Brewfile.
#######################################
save_packages() {
    verbose "Saving installed packages to Brewfile..."
    if [ "$DRY_RUN" = false ]; then
        brew bundle dump -f
        [ -d ~/.brew/ ] || mkdir -p ~/.brew/
        cp Brewfile ~/.brew/
        rm -f Brewfile
    fi
}

#######################################
# Update Homebrew and upgrade installed packages.
# Outputs:
#   Output to STDOUT.
#######################################
update_homebrew_packages() {
    verbose "Updating Homebrew and upgrading packages..."
    if [ "$DRY_RUN" = false ]; then
        brew update
        brew upgrade -g
    fi
}

# Main
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        --all-homebrew|-a)
            update_homebrew_packages
            clean_homebrew
            save_packages
            shift
            ;;
        --aws-profile)
            AWS_PROFILE="${2:-default}"
            aws_env_setup
            shift 2
            ;;
        --docker-cleanup|-d)
            docker_cleanup
            shift
            ;;
        --install-homebrew-packages|-i)
            FILE_NAME="${2:-$HOME/.brew/Brewfile}"
            install_packages
            shift 2
            ;;
        --save-homebrew-packages|-s)
            save_packages
            shift
            ;;
        --update-homebrew-packages|-u)
            update_homebrew_packages
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "ERROR: encountered invalid argument $1"
            usage
            exit 1
            ;;
    esac
done
