.DEFAULT_GOAL := help

# ==========================
# Variable Definitions
# ==========================

# Operating System Detection
UNAME_S := $(shell bash -c 'uname -s')
OS := $(shell bash -c 'uname -o' 2>/dev/null || echo "$(OS)")

# ==========================
# Phony Targets
# ==========================
.PHONY: all help setup mac_setup debian_setup rhel_setup windows_setup backup

# ==========================
# Default Target
# ==========================
all: setup

# ==========================
# Help Target
# ==========================
help:
	@$(info Setup Utility)
	@$(info )
	@$(info Available Targets:)
	@$(info   all                    Default target, detects OS and runs the corresponding setup.)
	@$(info   help                   Display this help message.)
	@$(info   mac_setup              Setup configuration for macOS.)
	@$(info   debian_setup           Setup configuration for Debian.)
	@$(info   rhel_setup             Setup configuration for RHEL.)
	@$(info   windows_setup          Setup configuration for Windows.)
	@$(info )
	@$(info Examples:)
	@$(info   make all               Run the default target.)
	@$(info   make mac_setup         Run the macOS setup.)
	@$(info   make debian_setup      Run the Debian setup.)
	@$(info   make rhel_setup        Run the RHEL setup.)
	@$(info   make windows_setup     Run the Windows setup.)
	@$(info )
	@$(info Note: To run any of these commands in dry mode, add '--dry-run' to the make command.)

# ==========================
# Backup Target
# ==========================
backup:
	@$(info --->Backing up files<---)
	@if [ -f $(HOME)/.zshrc ]; then cp $(HOME)/.zshrc $(HOME)/.zshrc.$(shell date +%Y%m%d).BAK; fi
	@if [ -f $(HOME)/.tmux.conf ]; then cp $(HOME)/.tmux.conf $(HOME)/.tmux.conf.$(shell date +%Y%m%d).BAK; fi
	@if [ -f $(HOME)/.gitignore ]; then cp $(HOME)/.gitignore $(HOME)/.gitignore.$(shell date +%Y%m%d).BAK; fi
	@if [ -f $(HOME)/.gitconfig ]; then cp $(HOME)/.gitconfig $(HOME)/.gitconfig.$(shell date +%Y%m%d).BAK; fi

# ==========================
# Setup Target
# ==========================
setup: backup
	@$(info --->Detecting operating system<---)
	@if [ "$(UNAME_S)" = "Darwin" ]; then
		$(MAKE) mac_setup
	elif [ "$(UNAME_S)" = "Linux" ]; then
		if grep -q "ID=debian" /etc/os-release; then
			$(MAKE) debian_setup
		elif grep -q "ID=rhel" /etc/os-release; then
			$(MAKE) rhel_setup
		else
			$(info Unsupported Linux distribution.)
			exit 1
		fi
	elif [ "$(OS)" = "Windows_NT" ]; then
		$(MAKE) windows_setup
	else
		$(info Unsupported operating system.)
		exit 1
	fi

# ==========================
# Setup for Mac
# ==========================
mac_setup: backup
	@$(info --->Setting up for Mac<---)
	cp -r aws $(HOME)/.aws
	cp -r brew $(HOME)/.brew
	cp -r ssh $(HOME)/.ssh
	mkdir -p $(HOME)/.config/nvim && cp -r nvim/* $(HOME)/.config/nvim/
	cp -r vim $(HOME)/.vim
	@if [ -f $(HOME)/.zshrc ] then
		cat zsh_config/.zshrc >> $(HOME)/.zshrc
	else
		cp zsh_config/.zshrc $(HOME)/.zshrc
	fi
	cp zsh_config/tmux.conf.local $(HOME)/.tmux.conf
	cp .gitignore $(HOME)/.gitignore
	cp .gitconfig $(HOME)/.gitconfig
	./scripts/mac_utils.sh -i
	./scripts/mac_utils.sh -a

# ==========================
# Setup for Debian
# ==========================
debian_setup: backup
	@$(info --->Setting up for Debian<---)
	cp -r aws $(HOME)/.aws
	cp -r ssh $(HOME)/.ssh
	mkdir -p $(HOME)/.config/nvim && cp -r nvim/* $(HOME)/.config/nvim/
	cp -r vim $(HOME)/.vim
	@if [ -f $(HOME)/.zshrc ] then
		cat zsh_config/.zshrc >> $(HOME)/.zshrc
	else
		cp zsh_config/.zshrc $(HOME)/.zshrc
	fi
	cp zsh_config/tmux.conf.local $(HOME)/.tmux.conf
	cp .gitignore $(HOME)/.gitignore
	cp .gitconfig $(HOME)/.gitconfig
	./scripts/debian_utils.sh -u

# ==========================
# Setup for RHEL
# ==========================
rhel_setup: backup
	@$(info --->Setting up for RHEL<---)
	cp -r aws $(HOME)/.aws
	cp -r ssh $(HOME)/.ssh
	mkdir -p $(HOME)/.config/nvim && cp -r nvim/* $(HOME)/.config/nvim/
	cp -r vim $(HOME)/.vim
	@if [ -f $(HOME)/.zshrc ] then
		cat zsh_config/.zshrc >> $(HOME)/.zshrc
	else
		cp zsh_config/.zshrc $(HOME)/.zshrc
	fi
	cp zsh_config/tmux.conf.local $(HOME)/.tmux.conf
	cp .gitignore $(HOME)/.gitignore
	cp .gitconfig $(HOME)/.gitconfig
	./scripts/rhel_utils.sh -u

# ==========================
# Setup for Windows
# ==========================
windows_setup: backup
	@$(info --->Setting up for Windows<---)
	cp -r powershell_config $(USERPROFILE)
	PowerShell -Command "Start-Process -Verb RunAs -FilePath $(USERPROFILE)\powershell_config\windows_utils.ps1"
