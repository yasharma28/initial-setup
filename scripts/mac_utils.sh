#!/bin/bash

# Usage Function
usage() {
    cat << EOF
${0##*/} [ -a ] [ -h ] [ -i ] [ -s ] [ -u ] [ --all-homebrew ] [--aws-profile ] [ --help ] [ --install-homebrew-packages ][ --save-homebrew-packages ] [ --update-homebrew-packages ]

NAME:
    utils.sh is a set of utility functions that is needed to setup/run programs smoothly.

DESCRIPTION:
    utils.sh is a set of utility functions that is needed to setup/run programs smoothly.<TODO>

OPTIONAL OPTIONS:
    -a, --all-homebrew
        Runs homebrew update, homebrew upgrade and save homebrew packages.

    --aws-profile AWS_PROFILE
        Set environment variables from AWS profile. By default it selects the "default" profile.

    -d, --docker-cleanup
        Cleanup all docker related stuff.

    -h, --help
        Prints the usage for the script and exits.

    -i, --install-homebrew-packages FILE_NAME
        Install packages for homebrew from a given file. By default it installs from "~/.brew/Brewfile".

    -s, --save-homebrew-packages
        Save packages running in hombrew to "~/.brew/Brewfile".

    -u, --update-homebrew-packages
        Update homebrew and upgrade its packages.
EOF
}

# Setup environment variables from AWS profile
aws_env_setup() {
  echo "Setup AWS ${AWS_PROFILE}."
  export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile ${AWS_PROFILE})
  export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile ${AWS_PROFILE})
  export AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile "${AWS_PROFILE}")
  export AWS_SECURITY_TOKEN=$(aws configure get aws_security_token --profile "${AWS_PROFILE}")
  export AWS_DEFAULT_REGION=$(aws configure get region --profile "${AWS_PROFILE}")
  echo "${AWS_PROFILE} environment variables exported."
}

# Cleanup homebrew
clean_homebrew() {
    brew cleanup --prune=all
}

# Complete cleanup of docker
docker_cleanup() {
    docker stop $(docker ps -aq)
    docker system prune -a -f
}

# Install list of packages
install_packages() {
    echo "Installing Packages from "${FILE_NAME}" file"
    brew bundle --no-lock --file="${FILE_NAME}"
}

# Saving list of installed packages
save_packages() {
    brew bundle dump -f
    [ -d ~/.brew/ ] || mkdir -p ~/.brew/
    cp Brewfile ~/.brew/
    rm -f Brewfile
}

# Upgrade Homebrew
update_homebrew_packages() {
    brew update
    brew upgrade
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
            shift
            shift
            ;;
        --docker-cleanup|-d)
            docker_cleanup
            shift
            ;;
        --install-homebrew-packages|-i)
            FILE_NAME="${2:-~/.brew/Brewfile}"
            shift
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
        *)
            echo "ERROR: encountered invalid argument $1"
            exit
            ;;
    esac
done
