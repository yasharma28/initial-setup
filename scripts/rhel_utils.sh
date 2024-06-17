#!/bin/bash

# Flag for dry run mode
DRY_RUN=false

#######################################
# Display usage information.
# Outputs:
#   Output to STDOUT.
#######################################
usage() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

A set of utility functions to setup/run programs smoothly.

OPTIONS:
  -h, --help                        Display this help message and exit.
  -u, --update-rhel-packages        Update RHEL and upgrade its packages.
  --dry-run                         Simulate the operations without executing them.

EXAMPLES:
  ${0##*/} --help
      Display this help message.

  ${0##*/} --update-rhel-packages
      Update RHEL and upgrade its packages.

  ${0##*/} --dry-run --update-rhel-packages
      Simulate the update of RHEL packages without making any changes.

EOF
}

#######################################
# Update RHEL packages.
# Globals:
#   DRY_RUN
# Outputs:
#   Output to STDOUT and STDERR.
#######################################
update_rhel_packages() {
    if $DRY_RUN; then
        echo "[DRY RUN] Would update package list."
        echo "[DRY RUN] Would upgrade installed packages."
        echo "[DRY RUN] Would remove unnecessary packages and clean up cached files."
        return
    fi

    # Check if the script is run as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Update the package list
    yum check-update

    # Upgrade all installed packages
    yum update -y

    # Clean up unnecessary packages and cached files
    yum autoremove -y
    yum clean all

    # Display a message indicating the update is complete
    echo "RHEL and all packages have been updated."
}

#######################################
# Main function to parse arguments and execute corresponding functions.
# Globals:
#   DRY_RUN
# Arguments:
#   Command line arguments.
# Outputs:
#   Output to STDOUT and STDERR.
#######################################
main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                usage
                exit 0
                ;;
            --update-rhel-packages|-u)
                update_rhel_packages
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
}

# Execute the main function with all the arguments
main "$@"
