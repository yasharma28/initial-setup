#!/bin/bash

# Usage Function
usage() {
    cat << EOF
${0##*/} [ -h ] [ -u ] [ --help ] [ --update-debian-packages ]

NAME:
    utils.sh is a set of utility functions that is needed to setup/run programs smoothly.

DESCRIPTION:
    utils.sh is a set of utility functions that is needed to setup/run programs smoothly.<TODO>

OPTIONAL OPTIONS:
    -h, --help
        Prints the usage for the script and exits.

    -u, --update-debian-packages
        Update Ubuntu and upgrade its packages.
EOF
}

# Update Debian packages
update_debian_packages() {
    # Check if the script is run as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Update the package list
    apt update

    # Upgrade all installed packages
    apt upgrade -y

    # Clean up unnecessary packages and cached files
    apt autoremove -y
    apt clean

    # Display a message indicating the update is complete
    echo "Ubuntu and all packages have been updated."
}

# Main
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        --update-debian-packages|-u)
            update_debian_packages
            shift
            ;;
        *)
            echo "ERROR: encountered invalid argument $1"
            exit
            ;;
    esac
done
