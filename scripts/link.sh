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
readonly DEFAULT_PACKAGES=(zsh tmux starship sesh nvim vim git ssh)
# Overlay packages aren't enumerated here: when --profile <name> is given,
# every stow/*-<name>/ dir is discovered at run-time and stowed after the
# base set. Adding a new overlay-capable tool (or a new profile entirely)
# is purely a matter of creating its directory under stow/.
#
# Note `aws` has NO base package symlinked: stow/aws/.aws/config.example is
# a reference only. The real ~/.aws/config comes from the overlay
# (stow/aws-personal/.aws/config, gitignored — see .gitignore).

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

# Count "substantive" lines in a file: anything that isn't blank, a comment
# starting with #, or a config-file comment starting with ;. Used to compare
# existing $HOME files against the stow-tree replacement below; a low count
# means the file is effectively a placeholder/template.
#
# grep -c always prints a count on stdout; we override to 0 only when grep
# fails (no matches → exit 1, or read error → exit 2). Without `local count`
# + the trailing `echo`, the previous `|| echo 0` chain emitted both grep's
# count AND a fallback 0 on no-match, breaking arithmetic in the caller.
substantive_lines() {
  local count
  count=$(grep -cvE '^\s*(#|;|$)' "$1" 2>/dev/null) || count=0
  echo "${count}"
}

# Refuse to clobber a real config file with a placeholder. Was the failure mode
# behind the aws-config wipe: link.sh moved a 30-line live SSO config aside and
# linked the repo's 4-line template in its place. Backup existed, but live state
# was broken until manual restore. We now require SAFETY_OVERRIDE=1 to allow
# replacing N substantive lines with substantially fewer.
guard_template_clobber() {
  local existing="$1" replacement="$2"
  local e_lines r_lines
  e_lines=$(substantive_lines "${existing}")
  r_lines=$(substantive_lines "${replacement}")
  # Threshold: existing has >3x more substantive content than replacement and
  # at least 5 substantive lines (filter out genuinely-tiny configs like a
  # 1-line .gitignore).
  if (( e_lines >= 5 )) && (( e_lines > r_lines * 3 )); then
    err "REFUSING to replace ${existing} (${e_lines} substantive lines)"
    err "  with ${replacement} (${r_lines} substantive lines)."
    err "  The repo file looks like a placeholder; ${existing} has real content."
    err "  Re-run with SAFETY_OVERRIDE=1 to force, or move the real config into"
    err "  a per-profile overlay package (stow/<pkg>-<profile>/) first."
    return 1
  fi
  return 0
}

# Back up any pre-existing real file at a package's target paths so stow won't
# refuse with a conflict. Existing symlinks (ours, from a prior run) are left
# for --restow to refresh.
backup_conflicts() {
  local pkg="$1" rel target source
  while IFS= read -r -d '' file; do
    rel="${file#"${STOW_DIR}/${pkg}/"}"
    target="${TARGET}/${rel}"
    source="${file}"
    if [[ -e "${target}" && ! -L "${target}" ]]; then
      if [[ "${SAFETY_OVERRIDE:-0}" != "1" ]]; then
        guard_template_clobber "${target}" "${source}" || return 1
      fi
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
  -p, --profile <name>     Also stow overlay packages named <pkg>-<name>
                           (e.g. zsh-personal, git-work) after the base set.
                           Any <name> with at least one overlay dir under
                           ${STOW_DIR##*/}/ is accepted.
  -h, --help               Show this help.

PACKAGES default to: ${DEFAULT_PACKAGES[*]}
EOF
}

# A profile is "known" if at least one stow/*-<profile>/ directory exists.
# This replaces a hardcoded personal|work allowlist: adding a new profile
# is now solely a matter of creating its overlay packages, with no editing
# of the validator. Empty result -> profile is unknown.
list_overlays_for_profile() {
  local profile="$1"
  compgen -G "${STOW_DIR}/*-${profile}" 2>/dev/null || true
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

  # Append profile overlays (e.g. zsh-personal, git-personal, ssh-personal,
  # aws-personal) if PROFILE was set. Profile validity is discovered from the
  # filesystem — any name with at least one stow/*-<profile>/ directory is
  # accepted. Adding a new profile is purely a matter of creating its overlay
  # directories; this script does not need to be edited.
  if [[ -n "${PROFILE}" ]]; then
    local discovered
    discovered=$(list_overlays_for_profile "${PROFILE}")
    if [[ -z "${discovered}" ]]; then
      err "no overlay packages found under ${STOW_DIR##*/}/*-${PROFILE}/"
      err "  create at least one overlay dir (e.g. stow/zsh-${PROFILE}/) first."
      exit "${EXIT_USAGE}"
    fi
    while IFS= read -r overlay_path; do
      packages+=("${overlay_path##*/}")
    done <<< "${discovered}"
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
