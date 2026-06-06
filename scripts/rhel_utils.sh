#!/usr/bin/env bash
# == rhel_utils.sh ==
# Provisions the terminal stack on RHEL/Fedora and updates system packages via
# dnf (the modern replacement for yum). Neovim comes from the official release
# tarball because the distro build is usually too old for the treesitter main
# branch (which needs Neovim 0.11+).
set -euo pipefail

readonly LOCAL_BIN="${HOME}/.local/bin"
readonly NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
readonly NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}"

readonly EXIT_USAGE=1

err() { echo "[ERROR] $(date '+%H:%M:%S') $*" >&2; }
log() { echo "[INFO]  $(date '+%H:%M:%S') $*"; }

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS]

  -i, --install   Install the terminal stack (dnf tools + neovim + starship + sesh).
  -u, --update    Update and upgrade system packages (must run as root).
  -h, --help      Show this help.
EOF
}

install_dnf_tools() {
  log "installing base tools via dnf (sudo)"
  sudo dnf install -y \
    gcc gcc-c++ make curl git stow tmux fzf zoxide ripgrep zsh unzip
}

install_neovim() {
  if command -v nvim &>/dev/null; then
    log "neovim already present: $(nvim --version | head -1)"
    return 0
  fi
  log "installing neovim from official release tarball"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  curl -fsSL -o "${tmp}/${NVIM_TARBALL}" "${NVIM_URL}"
  tar -C "${HOME}/.local" -xzf "${tmp}/${NVIM_TARBALL}" --strip-components=1
  mkdir -p "${LOCAL_BIN}"
}

install_starship() {
  command -v starship &>/dev/null && { log "starship present"; return 0; }
  log "installing starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "${LOCAL_BIN}"
}

install_sesh() {
  command -v sesh &>/dev/null && { log "sesh present"; return 0; }
  if command -v go &>/dev/null; then
    log "installing sesh via go install"
    go install github.com/joshmedeski/sesh/v2@latest
  else
    err "sesh needs Go (or a release binary) — install Go or grab a release from"
    err "https://github.com/joshmedeski/sesh/releases and place it on PATH"
  fi
}

install_stack() {
  install_dnf_tools
  install_neovim
  install_starship
  install_sesh
  log "stack installed — run scripts/bootstrap_terminal.sh next (the Makefile does this)"
}

update_packages() {
  if [[ ${EUID} -ne 0 ]]; then
    err "package update must run as root"
    exit "${EXIT_USAGE}"
  fi
  log "updating dnf packages"
  dnf upgrade -y
  dnf autoremove -y
  dnf clean all
}

main() {
  [[ $# -eq 0 ]] && { usage; exit "${EXIT_USAGE}"; }
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -i|--install) install_stack; shift ;;
      -u|--update) update_packages; shift ;;
      *) err "invalid argument: $1"; usage; exit "${EXIT_USAGE}" ;;
    esac
  done
}

main "$@"
