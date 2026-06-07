# BEGIN_HEADER
########################################################################
# DESCRIPTION:
#   This Makefile manages environment setup (e.g., macOS, Debian, RHEL, Windows).
#   It handles:
#     - File backups
#     - OS detection
#     - Per-platform configuration installs
#
# Best Practices:
#   - Use `make help` to see available targets and their usage
#   - Run `make all` (default) to detect OS and perform setup
#   - Perform backups via `make backup` before changes
#   - Update this header block when making significant changes
#
# Author: Yash Sharma
# Version: 1.0.0
# Last Updated: March 2025
# Maintainer: Yash Sharma
########################################################################
# END_HEADER

SHELL := /bin/bash
.DEFAULT_GOAL := help

# OS detection + a timestamp for backups.
UNAME_S := $(shell uname -s)
DATE    := $(shell date +%Y%m%d%H%M%S)

# Extra app profile layered on the core stack: personal | work (empty = core).
PROFILE ?=

# Dotfile packages symlinked by scripts/link.sh.
PACKAGES := zsh tmux starship sesh nvim vim git ssh aws

.PHONY: help all setup backup mac_setup debian_setup rhel_setup windows_setup \
        lint unlink clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Targets:\n"} \
		/^[a-zA-Z_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: setup ## Alias for setup

setup: backup ## Detect the OS and run the matching setup
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		$(MAKE) mac_setup; \
	elif [ "$(UNAME_S)" = "Linux" ]; then \
		if grep -qiE 'debian|ubuntu' /etc/os-release; then $(MAKE) debian_setup; \
		elif grep -qiE 'rhel|fedora|centos|rocky|almalinux' /etc/os-release; then $(MAKE) rhel_setup; \
		else echo "Unsupported Linux distribution." >&2; exit 1; fi; \
	else \
		echo "Unsupported OS: $(UNAME_S)" >&2; exit 1; \
	fi

backup: ## Snapshot existing dotfiles to dated .BAK copies
	@echo "==> Backing up existing dotfiles"
	@for f in $(HOME)/.zshrc $(HOME)/.tmux.conf.local $(HOME)/.gitconfig \
	          $(HOME)/.gitignore $(HOME)/.config/starship.toml $(HOME)/.ssh/config; do \
		if [ -f "$$f" ] && [ ! -L "$$f" ]; then cp "$$f" "$$f.$(DATE).BAK"; fi; \
	done
	@if [ -d $(HOME)/.aws ]; then cp -r $(HOME)/.aws $(HOME)/.aws.$(DATE).BAK; fi
	@# nvim: must MOVE (not cp) so the new lazy.nvim stow tree lands on a
	@# clean dir. Old packer-era files under after/plugin/ would otherwise
	@# auto-source on startup and conflict with lazy's plugin specs.
	@if [ -d $(HOME)/.config/nvim ] && [ ! -L $(HOME)/.config/nvim ]; then \
		mv $(HOME)/.config/nvim $(HOME)/.config/nvim.$(DATE).BAK; fi

# Shared post-install steps for every per-OS setup target. Args:
#   $(1) is currently unused — kept positional in case a future OS needs to
#        pass extra context (architecture, distro variant) into bootstrap.
# Single source of truth for "stow dotfiles + bootstrap terminal stack",
# so adding an OS only adds the package-install line, not the boilerplate.
define stow_and_bootstrap
	@echo "==> Symlinking dotfiles via Stow (PROFILE=$(PROFILE))"
	./scripts/link.sh $(if $(PROFILE),--profile $(PROFILE),)
	@echo "==> Bootstrapping oh-my-zsh, gpakosz tmux, tpm, nvim"
	./scripts/bootstrap_terminal.sh
endef

mac_setup: backup ## macOS setup (PROFILE=personal|work for extra apps)
	@echo "==> Installing Homebrew packages (PROFILE=$(PROFILE))"
	./scripts/mac_utils.sh -i $(PROFILE)
	$(call stow_and_bootstrap)

debian_setup: backup ## Debian/Ubuntu setup
	@echo "==> Installing terminal stack"
	./scripts/debian_utils.sh -i
	$(call stow_and_bootstrap)
	@echo "==> System update needs root: sudo ./scripts/debian_utils.sh -u"

rhel_setup: backup ## RHEL/Fedora setup
	@echo "==> Installing terminal stack"
	./scripts/rhel_utils.sh -i
	$(call stow_and_bootstrap)
	@echo "==> System update needs root: sudo ./scripts/rhel_utils.sh -u"

windows_setup: backup ## Windows setup (run from PowerShell)
	powershell -ExecutionPolicy Bypass -File scripts/windows_utils.ps1 -Profile $(if $(PROFILE),$(PROFILE),core)

lint: ## Lint shell (shellcheck), Lua (stylua), YAML (yamllint)
	shellcheck scripts/*.sh
	stylua --check stow/nvim/.config/nvim
	yamllint .

unlink: ## Remove the Stow symlinks from $HOME (include PROFILE= overlays)
	stow -D --dir stow --target $(HOME) $(PACKAGES)
	@# Overlay teardown is discovery-driven (mirrors link.sh): every
	@# stow/*-$(PROFILE)/ that exists gets unstowed. Adding new overlay-capable
	@# tools or new profiles requires no edits here.
	@if [ -n "$(PROFILE)" ]; then \
		for d in stow/*-$(PROFILE); do \
			[ -d "$$d" ] && stow -D --dir stow --target $(HOME) "$${d##*/}" || true; \
		done; \
	fi

clean: ## Remove dated .BAK / pre-stow backups from $HOME
	@echo "==> Removing backups"
	@find $(HOME) -maxdepth 2 -name '*.BAK' -exec rm -rf {} + 2>/dev/null || true
	@find $(HOME) -maxdepth 3 -name '*.pre-stow.*.bak' -exec rm -rf {} + 2>/dev/null || true
