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
	@if [ -d $(HOME)/.config/nvim ] && [ ! -L $(HOME)/.config/nvim ]; then \
		cp -r $(HOME)/.config/nvim $(HOME)/.config/nvim.$(DATE).BAK; fi

mac_setup: backup ## macOS setup (PROFILE=personal|work for extra apps)
	@echo "==> Installing Homebrew packages (PROFILE=$(PROFILE))"
	./scripts/mac_utils.sh -i $(PROFILE)
	@echo "==> Symlinking dotfiles via Stow (PROFILE=$(PROFILE))"
	./scripts/link.sh $(if $(PROFILE),--profile $(PROFILE),)
	@echo "==> Bootstrapping oh-my-zsh, gpakosz tmux, tpm, nvim"
	./scripts/bootstrap_terminal.sh

debian_setup: backup ## Debian/Ubuntu setup
	@echo "==> Installing terminal stack"
	./scripts/debian_utils.sh -i
	@echo "==> Symlinking dotfiles via Stow (PROFILE=$(PROFILE))"
	./scripts/link.sh $(if $(PROFILE),--profile $(PROFILE),)
	@echo "==> Bootstrapping oh-my-zsh, gpakosz tmux, tpm, nvim"
	./scripts/bootstrap_terminal.sh
	@echo "==> System update needs root: sudo ./scripts/debian_utils.sh -u"

rhel_setup: backup ## RHEL/Fedora setup
	@echo "==> Installing terminal stack"
	./scripts/rhel_utils.sh -i
	@echo "==> Symlinking dotfiles via Stow (PROFILE=$(PROFILE))"
	./scripts/link.sh $(if $(PROFILE),--profile $(PROFILE),)
	@echo "==> Bootstrapping oh-my-zsh, gpakosz tmux, tpm, nvim"
	./scripts/bootstrap_terminal.sh
	@echo "==> System update needs root: sudo ./scripts/rhel_utils.sh -u"

windows_setup: backup ## Windows setup (run from PowerShell)
	powershell -ExecutionPolicy Bypass -File scripts/windows_utils.ps1 -Profile $(if $(PROFILE),$(PROFILE),core)

lint: ## Lint shell (shellcheck), Lua (stylua), YAML (yamllint)
	shellcheck scripts/*.sh
	stylua --check stow/nvim/.config/nvim
	yamllint .

unlink: ## Remove the Stow symlinks from $HOME (include PROFILE= overlays)
	stow -D --dir stow --target $(HOME) $(PACKAGES)
	@if [ -n "$(PROFILE)" ]; then \
		for o in zsh-$(PROFILE) git-$(PROFILE) ssh-$(PROFILE); do \
			[ -d stow/$$o ] && stow -D --dir stow --target $(HOME) $$o || true; \
		done; \
	fi

clean: ## Remove dated .BAK / pre-stow backups from $HOME
	@echo "==> Removing backups"
	@find $(HOME) -maxdepth 2 -name '*.BAK' -exec rm -rf {} + 2>/dev/null || true
	@find $(HOME) -maxdepth 3 -name '*.pre-stow.*.bak' -exec rm -rf {} + 2>/dev/null || true
