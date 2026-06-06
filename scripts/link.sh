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
# Packages that have a per-profile overlay variant in stow/<pkg>-<profile>/.
# When --profile is given, each name here is suffixed and stowed after the base.
readonly PROFILE_OVERLAYS=(zsh git ssh)

# DRY_RUN=1 enables preview mode — no backups moved, no symlinks created.
# Useful before first run on a populated $HOME to see what will be touched.
DRY_RUN="${DRY_RUN:-0}"
# PROFILE selects which overlay packages get stowed after the base set.
# Empty string = no overlays. Accepts: personal, work.
PROFILE="${PROFILE:-}"

readonly EXIT_DEPENDENCY=2
readonly EXIT_USAGE=64

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
      if [[ "${DRY_RUN}" == "1" ]]; then
        log "[dry-run] would back up ${target} -> ${target}${BACKUP_SUFFIX}"
      else
        log "backing up ${target} -> ${target}${BACKUP_SUFFIX}"
        mv "${target}" "${target}${BACKUP_SUFFIX}"
      fi
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
  if [[ "${DRY_RUN}" == "1" ]]; then
    # Don't invoke stow --simulate here: in dry-run the backup didn't actually
    # move the conflicting file, so stow would always abort with a conflict.
    # The backup_conflicts dry-run output above already enumerated every file
    # that would be touched — that's the meaningful preview.
    log "[dry-run] would stow ${pkg}"
  else
    log "stowing ${pkg}"
    stow --no-folding --dir "${STOW_DIR}" --target "${TARGET}" --restow "${pkg}"
  fi
}

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS] [PACKAGES...]

  -n, --dry-run            Preview backups + stow actions; touch nothing.
  -p, --profile <name>     Also stow overlay packages (zsh-<name>, git-<name>,
                           ssh-<name>) after the base set. Valid: personal, work.
  -h, --help               Show this help.

PACKAGES default to: ${DEFAULT_PACKAGES[*]}
EOF
}

main() {
  local packages=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -n|--dry-run) DRY_RUN=1; shift ;;
      -p|--profile)
        [[ -n "${2:-}" ]] || { err "--profile requires an argument"; exit "${EXIT_USAGE}"; }
        PROFILE="$2"; shift 2 ;;
      -*) err "unknown flag: $1"; usage; exit "${EXIT_USAGE}" ;;
      *) packages+=("$1"); shift ;;
    esac
  done
  require_stow

  if [[ ${#packages[@]} -eq 0 ]]; then
    packages=("${DEFAULT_PACKAGES[@]}")
  fi

  # Append profile overlays (e.g. zsh-personal, git-personal, ssh-personal) if
  # PROFILE was set. Skip any overlay package directory that doesn't exist —
  # the work overlay may not be populated yet.
  if [[ -n "${PROFILE}" ]]; then
    case "${PROFILE}" in
      personal|work) : ;;
      *) err "unknown PROFILE '${PROFILE}' (valid: personal, work)"; exit "${EXIT_USAGE}" ;;
    esac
    for base in "${PROFILE_OVERLAYS[@]}"; do
      local overlay="${base}-${PROFILE}"
      if [[ -d "${STOW_DIR}/${overlay}" ]]; then
        packages+=("${overlay}")
      else
        log "no overlay package '${overlay}' — skipping"
      fi
    done
  fi

  [[ "${DRY_RUN}" == "1" ]] && log "DRY-RUN MODE — no files will be moved or symlinked"
  [[ -n "${PROFILE}" ]] && log "PROFILE=${PROFILE}"
  for pkg in "${packages[@]}"; do
    link_package "${pkg}"
  done
  if [[ "${DRY_RUN}" != "1" ]]; then
    # ssh is strict about a world-writable config; tighten it (follows the symlink).
    [[ -e "${HOME}/.ssh/config" ]] && chmod 600 "${HOME}/.ssh/config" 2>/dev/null || true
  fi
  log "stow complete"
}

main "$@"
