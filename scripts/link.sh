#!/usr/bin/env bash
# == link.sh ==
# Symlinks the per-tool dotfile packages from stow/ into $HOME via GNU Stow, so
# the repo stays the single source of truth (edits write back through the link).
# Pre-existing real files are backed up (timestamped) before linking, so nothing
# is silently clobbered. We only ever manage config files — SSH keys and real
# AWS credentials are never enumerated or touched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_SUFFIX=".pre-stow.$(date +%Y%m%d%H%M%S).bak"
readonly SCRIPT_DIR REPO_ROOT BACKUP_SUFFIX
readonly STOW_DIR="${REPO_ROOT}/stow"
readonly TARGET="${HOME}"
readonly DEFAULT_PACKAGES=(zsh tmux starship sesh nvim vim git ssh aws)

readonly EXIT_DEPENDENCY=2

err() { echo "[ERROR] $(date '+%H:%M:%S') $*" >&2; }
log() { echo "[INFO]  $(date '+%H:%M:%S') $*"; }

require_stow() {
  if ! command -v stow &>/dev/null; then
    err "GNU Stow not installed — run 'brew install stow' (it's in the core Brewfile)"
    exit "${EXIT_DEPENDENCY}"
  fi
}

# Back up any pre-existing real file at a package's target paths so stow won't
# refuse with a conflict. Existing symlinks (ours, from a prior run) are left
# for --restow to refresh.
backup_conflicts() {
  local pkg="$1" rel target
  while IFS= read -r -d '' file; do
    rel="${file#"${STOW_DIR}/${pkg}/"}"
    target="${TARGET}/${rel}"
    if [[ -e "${target}" && ! -L "${target}" ]]; then
      log "backing up ${target} -> ${target}${BACKUP_SUFFIX}"
      mv "${target}" "${target}${BACKUP_SUFFIX}"
    fi
  done < <(find "${STOW_DIR}/${pkg}" -type f -print0)
}

link_package() {
  local pkg="$1"
  if [[ ! -d "${STOW_DIR}/${pkg}" ]]; then
    err "no such package: ${pkg}"
    return 1
  fi
  backup_conflicts "${pkg}"
  log "stowing ${pkg}"
  stow --no-folding --dir "${STOW_DIR}" --target "${TARGET}" --restow "${pkg}"
}

main() {
  require_stow
  local packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then
    packages=("${DEFAULT_PACKAGES[@]}")
  fi
  for pkg in "${packages[@]}"; do
    link_package "${pkg}"
  done
  # ssh is strict about a world-writable config; tighten it (follows the symlink).
  [[ -e "${HOME}/.ssh/config" ]] && chmod 600 "${HOME}/.ssh/config" 2>/dev/null || true
  log "stow complete"
}

main "$@"
