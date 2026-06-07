#!/usr/bin/env bash
# == bootstrap_terminal.sh ==
# Installs the terminal-stack frameworks that Homebrew can't: oh-my-zsh, the
# gpakosz tmux framework, tpm + its plugins, and a one-time Neovim warmup.
# Idempotent — safe to re-run; skips anything already present. Run it AFTER the
# config files (.zshrc, .tmux.conf.local, nvim/) are in place, because tpm reads
# the plugin list from ~/.tmux.conf.local and the nvim warmup needs the config.
set -euo pipefail

readonly OMZ_DIR="${HOME}/.oh-my-zsh"
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-${OMZ_DIR}/custom}"
readonly TMUX_DIR="${HOME}/.tmux"
readonly TPM_DIR="${TMUX_DIR}/plugins/tpm"

log() { echo "[INFO]  $(date '+%H:%M:%S') $*"; }
warn() { echo "[WARN]  $(date '+%H:%M:%S') $*" >&2; }

install_oh_my_zsh() {
  if [[ -d "${OMZ_DIR}" ]]; then
    log "oh-my-zsh already installed"
    return 0
  fi
  log "installing oh-my-zsh"
  # KEEP_ZSHRC: don't touch our own .zshrc (deployed separately).
  # RUNZSH/CHSH=no: don't drop into a shell or rewrite the login shell.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_autosuggestions() {
  local -r dest="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
  if [[ -d "${dest}" ]]; then
    log "zsh-autosuggestions already installed"
    return 0
  fi
  log "installing zsh-autosuggestions"
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "${dest}"
}

install_gpakosz_tmux() {
  if [[ ! -d "${TMUX_DIR}" ]]; then
    log "cloning gpakosz/.tmux"
    git clone https://github.com/gpakosz/.tmux.git "${TMUX_DIR}"
  else
    # Always fast-forward to upstream. The framework file (.tmux.conf) is
    # never edited locally — only .tmux.conf.local is, and that's stowed
    # from this repo — so --ff-only is safe and a divergence is a real
    # problem (likely manual edit) the user should see, not auto-resolve.
    log "updating gpakosz/.tmux (git pull --ff-only)"
    if ! git -C "${TMUX_DIR}" pull --ff-only --quiet; then
      warn "gpakosz/.tmux pull failed (local changes or non-FF remote?) — skipping update"
    fi
  fi
  # ~/.tmux.conf must symlink to the framework; our edits live in .tmux.conf.local.
  ln -sf "${TMUX_DIR}/.tmux.conf" "${HOME}/.tmux.conf"
}

install_tpm() {
  if [[ -d "${TPM_DIR}" ]]; then
    log "tpm already installed"
    return 0
  fi
  log "installing tpm"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "${TPM_DIR}"
}

# Install the tpm plugins (resurrect/continuum) without the interactive prefix+I.
# Needs a running server so tpm can source the config; cleaned up afterward.
install_tmux_plugins() {
  if ! command -v tmux &>/dev/null; then
    warn "tmux not on PATH — skipping plugin install (run prefix+I later)"
    return 0
  fi
  if [[ ! -x "${TPM_DIR}/bin/install_plugins" ]]; then
    warn "tpm install_plugins missing — skipping"
    return 0
  fi
  log "installing tmux plugins via tpm"
  tmux new-session -d -s __bootstrap__ 2>/dev/null || true
  "${TPM_DIR}/bin/install_plugins" || warn "tpm returned non-zero; run prefix+I in tmux"
  tmux kill-session -t __bootstrap__ 2>/dev/null || true
}

# Pre-install nvim plugins and treesitter parsers so the first real launch is
# instant. Lazy/treesitter would also self-install on first open, so failures
# here are non-fatal.
warmup_neovim() {
  if ! command -v nvim &>/dev/null; then
    warn "nvim not on PATH — skipping warmup"
    return 0
  fi
  log "syncing lazy.nvim plugins"
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "lazy sync incomplete — finishes on first nvim launch"
  log "compiling treesitter parsers"
  nvim --headless "+TSUpdate" +qa 2>/dev/null || warn "TSUpdate incomplete — needs tree-sitter CLI on PATH"
}

main() {
  install_oh_my_zsh
  install_zsh_autosuggestions
  install_gpakosz_tmux
  install_tpm
  install_tmux_plugins
  warmup_neovim
  log "terminal bootstrap complete"
}

main "$@"
