#========================================================
# TERMINAL SESSION MANAGEMENT
#========================================================
# Detect the Homebrew prefix without spawning `brew` (a per-shell subprocess is
# slow). Checks a no-sudo home prefix first, then the Apple Silicon and Intel
# defaults; everything below references $HOMEBREW_PREFIX. Keeps this file
# portable across machines with Homebrew installed in different locations.
for _brew_prefix in "$HOME/homebrew" /opt/homebrew /usr/local; do
  if [[ -x "$_brew_prefix/bin/brew" ]]; then
    export HOMEBREW_PREFIX="$_brew_prefix"
    break
  fi
done
unset _brew_prefix

# Put Homebrew's bin on PATH now — the tmux auto-launch below must find
# Homebrew's tmux before the full PATH array is assembled later in this file.
# (typeset -U dedupes the duplicate when the path=() block runs.)
[[ -n "$HOMEBREW_PREFIX" ]] && export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Auto-attach tmux early, before the rest of shell init. Real interactive
# terminals only: -t 1 and TERM_PROGRAM guards keep it from firing in IDE,
# tool, or non-tty shells, which fail with "open terminal failed: not a terminal".
if command -v tmux &>/dev/null \
   && [[ -o interactive ]] && [[ -t 1 ]] && [[ -z "$TMUX" ]] \
   && [[ "$TERM" != screen* && "$TERM" != tmux* ]] \
   && [[ "$TERM_PROGRAM" == "iTerm.app" || "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
  exec tmux new-session -A -s default
fi

#========================================================
# OH-MY-ZSH CONFIGURATION
#========================================================
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# Empty: let oh-my-zsh skip theme loading entirely. Starship (initialized at the
# end of this file) owns the prompt — an oh-my-zsh theme here would just conflict.
ZSH_THEME=""

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

#========================================================
# PACKAGE MANAGERS & PATH CONFIGURATION
#========================================================
# XDG Base Directory specification
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"

# Consolidated PATH management
# Define all custom paths in order of priority (highest to lowest)
typeset -U path  # -U flag ensures uniqueness
path=(
  "${HOME}/.local/bin"
  "${HOME}/bin"
  "${HOMEBREW_PREFIX}/bin"
  "${HOMEBREW_PREFIX}/sbin"
  "${KREW_ROOT:-$HOME/.krew}/bin"
  "${HOMEBREW_PREFIX}/apps/Obsidian.app/Contents/MacOS"  # Obsidian CLI (moved from .zprofile)
  $path
)
export PATH

# Homebrew Settings (HOMEBREW_PREFIX is detected at the top of this file)
export HOMEBREW_CASK_OPTS="--appdir=${HOMEBREW_PREFIX}/apps --caskroom=${HOMEBREW_PREFIX}/caskroom"
export HOMEBREW_BUNDLE_FILE="${HOME}/.brew/Brewfile"
export HOMEBREW_NO_ENV_HINTS=1

# Reuse HOMEBREW_PREFIX (set above) instead of spawning `brew --prefix` per shell
export BREW_PREFIX="${HOMEBREW_PREFIX}"
export CPPFLAGS="-I${BREW_PREFIX}/include"
export LDFLAGS="-L${BREW_PREFIX}/lib"

# NVM Settings
export NVM_DIR="${HOME}/.nvm"
if [[ -d "${NVM_DIR}" ]]; then
  source "${NVM_DIR}/nvm.sh" --no-use  # Lazy loading for faster shell startup
  [[ -s "${NVM_DIR}/bash_completion" ]] && source "${NVM_DIR}/bash_completion"
fi

#========================================================
# CLOUD & DEVOPS TOOLS
#========================================================
# Google Cloud SDK
if [[ -n "${BREW_PREFIX}" && -f "${BREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc" ]]; then
  source "${BREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc"
  source "${BREW_PREFIX}/share/google-cloud-sdk/completion.zsh.inc"
fi

# Docker CLI completions
if [[ -d "${HOME}/.docker/completions" ]]; then
  fpath=("${HOME}/.docker/completions" $fpath)
fi
[[ -f "${HOME}/.docker/init-zsh.sh" ]] && source "${HOME}/.docker/init-zsh.sh"

# bashcompinit enables bash-style completions (Terraform's `complete -C` below).
# oh-my-zsh already ran compinit during its load, so don't run it a second time.
autoload -U +X bashcompinit && bashcompinit

# Terraform completion
if [[ -x "${HOMEBREW_PREFIX}/bin/terraform" ]]; then
  complete -o nospace -C "${HOMEBREW_PREFIX}/bin/terraform" terraform
fi

#========================================================
# DEVELOPMENT ENVIRONMENT
#========================================================
# Environment variables
export RIPGREP_CONFIG_PATH="${HOME}/.ripgrep"
export VAULT_ADDR="https://usa1r.vault.stage.pdce.io/"

# direnv hook (if available)
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# fzf shell integration — Ctrl-R history search, Ctrl-T file picker, Alt-C cd
command -v fzf &>/dev/null && source <(fzf --zsh)

# zoxide — `z <dir>` smart jump; also records visited dirs to feed sesh's picker
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Load local bin env if it exists
[[ -f "${HOME}/.local/bin/env" ]] && source "${HOME}/.local/bin/env"

#========================================================
# ALIASES & SHORTCUTS
#========================================================
# Kubernetes aliases
alias k=kubectl
alias kc=kubectx
alias kn=kubens

#========================================================
# AWS FUNCTIONS
#========================================================
# AWS SSO login function - usage: aws-sso <profile>
# Logs into AWS SSO and sets the profile in one command
aws-sso() {
  local profile="${1:?Usage: aws-sso <profile-name>}"
  export AWS_PROFILE="$profile"
  aws sso login --profile "$profile" && \
    echo "Logged in and switched to profile: $profile"
}

# List available AWS profiles for convenience
aws-profiles() {
  aws configure list-profiles 2>/dev/null || \
    grep '\[profile' ~/.aws/config | sed 's/\[profile \(.*\)\]/\1/'
}

# IAM role injector path
_IAM_INJECTOR="${HOME}/Documents/github_earth_dimension_c132/devops/iam-role-injector/meta_assume.sh"

# IAM role assume function - usage: assume <role>
assume() {
  local role="${1:?Usage: assume <role-name>}"
  if [[ -f "$_IAM_INJECTOR" ]]; then
    source "$_IAM_INJECTOR" "$role"
  else
    echo "Error: IAM injector not found at $_IAM_INJECTOR" >&2
    return 1
  fi
}

# Short aliases for frequently used roles (optional convenience)
alias dev='assume dev'
alias pci-dev='assume pcidev'
alias staging='assume staging'
alias pci-staging='assume pcistaging'
alias prd='assume prd'
alias pci-prd='assume pciprod'
alias devops='assume ops_devops'
alias hashi-ops='assume hashi'

#========================================================
# SECURITY & SECRETS
#========================================================
# Import secrets (load last to allow overrides)
[[ -f "${HOME}/.secrets.sh" ]] && source "${HOME}/.secrets.sh"
[[ -f "${HOME}/.secrets.txt" ]] && source "${HOME}/.secrets.txt"

# Added by codebase-memory-mcp install
export PATH="/Users/ysharma/.local/bin:$PATH"

#========================================================
# PROMPT (Starship)
#========================================================
# Initialized last so it sees the final PATH/env and wins the prompt over
# oh-my-zsh. Replaces Powerlevel10k. Config: ~/.config/starship.toml
eval "$(starship init zsh)"
