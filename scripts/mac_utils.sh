#!/usr/bin/env bash
# == mac_utils.sh ==
# Homebrew helpers for macOS setup + maintenance: install from the split
# Brewfiles, update/upgrade/cleanup, and snapshot installed packages. Kept
# deliberately small — simple err/log + a few explicit exit codes, no elaborate
# error-code framework. AWS auth is SSO-based (see stow/aws/.aws/config), so
# there is intentionally no static-key helper here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT
readonly BREW_DIR="${REPO_ROOT}/brew"
readonly CORE_BREWFILE="${BREW_DIR}/Brewfile"

readonly EXIT_USAGE=1
readonly EXIT_DEPENDENCY=2
readonly EXIT_BREW=3

err() { echo "[ERROR] $(date '+%H:%M:%S') $*" >&2; }
log() { echo "[INFO]  $(date '+%H:%M:%S') $*"; }

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS]

  -i, --install [PROFILE]  Install the core Brewfile, plus Brewfile.<PROFILE>
                           (personal|work) when PROFILE is given.
  -u, --update             brew update && brew upgrade.
  -a, --all                Update, upgrade, gcloud update, cleanup, snapshot.
  -d, --docker-cleanup     Stop containers and prune the Docker system.
  -s, --save               Snapshot installed packages to brew/Brewfile.dump
                           (does NOT overwrite the curated Brewfiles).
  -h, --help               Show this help.
EOF
}

require_brew() {
  if ! command -v brew &>/dev/null; then
    err "Homebrew not installed — see https://brew.sh"
    exit "${EXIT_DEPENDENCY}"
  fi
}

# Install core Brewfile, then the profile overlay if one was requested.
install_packages() {
  local profile="${1:-}"
  log "installing core Brewfile"
  brew bundle --file="${CORE_BREWFILE}" || { err "core bundle failed"; exit "${EXIT_BREW}"; }
  if [[ -n "${profile}" ]]; then
    local overlay="${BREW_DIR}/Brewfile.${profile}"
    if [[ -f "${overlay}" ]]; then
      log "installing ${profile} overlay"
      brew bundle --file="${overlay}" || { err "${profile} bundle failed"; exit "${EXIT_BREW}"; }
    else
      err "no overlay for profile '${profile}' (${overlay}) — skipping"
    fi
  fi
  log "package install complete"
}

update_packages() {
  log "updating Homebrew"
  brew update || { err "brew update failed"; exit "${EXIT_BREW}"; }
  log "upgrading packages"
  brew upgrade || { err "brew upgrade failed"; exit "${EXIT_BREW}"; }
}

gcloud_update() {
  command -v gcloud &>/dev/null && gcloud components update -q || true
}

clean_homebrew() {
  log "cleaning Homebrew"
  brew cleanup --prune=all || err "cleanup returned non-zero"
}

docker_cleanup() {
  command -v docker &>/dev/null || { err "docker not installed"; return 1; }
  log "stopping docker compose services (if any in cwd)"
  docker compose down 2>/dev/null || true
  log "pruning buildx caches"
  docker buildx prune -a -f || err "buildx prune returned non-zero"
  log "removing 'multiarch' buildx builder (if present)"
  docker buildx rm multiarch 2>/dev/null || true
  log "stopping containers + pruning Docker system"
  docker ps -aq | xargs -r docker stop || true
  docker system prune -a -f --volumes || err "docker prune returned non-zero"
}

# Snapshot to a scratch file — never overwrite the curated split Brewfiles.
save_snapshot() {
  local dump="${BREW_DIR}/Brewfile.dump"
  log "snapshotting installed packages to ${dump} (reconcile manually)"
  brew bundle dump -f --file="${dump}" || err "bundle dump returned non-zero"
}

main() {
  require_brew
  [[ $# -eq 0 ]] && { usage; exit "${EXIT_USAGE}"; }
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -i|--install)
        if [[ -n "${2:-}" && "$2" != -* ]]; then install_packages "$2"; shift 2
        else install_packages ""; shift; fi ;;
      -u|--update) update_packages; shift ;;
      -a|--all) update_packages; gcloud_update; clean_homebrew; save_snapshot; shift ;;
      -d|--docker-cleanup) docker_cleanup; shift ;;
      -s|--save) save_snapshot; shift ;;
      *) err "invalid argument: $1"; usage; exit "${EXIT_USAGE}" ;;
    esac
  done
}

main "$@"
