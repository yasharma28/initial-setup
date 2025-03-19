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

#######################################
# System Variables
#######################################
UNAME_S := $(shell uname -s)
OS := $(shell bash -c 'uname -o' 2>/dev/null || echo "$(OS)")

#######################################
# Phony Targets
#######################################
.PHONY: help all backup setup mac_setup debian_setup rhel_setup windows_setup

#######################################
# Helper Function
#######################################
define log_info
	@echo "--->[$(shell date "+%H:%M:%S")] $(1)<---"
endef

#######################################
# Help Target
#######################################
help: ## Show this help message
	@echo "Environment Setup Utility"
	@echo
	@awk '/^# BEGIN_HEADER/,/^# END_HEADER/ { if (!/^(# BEGIN_HEADER|# END_HEADER)/) print }' $(MAKEFILE_LIST)
	@echo
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z0-9\-_]+:.*?## / \
	{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo
	@echo "Notes:"
	@echo "  Add '--dry-run' to make commands if you want a dry run."

#######################################
# Default Target
#######################################
all: ## Default target: detects OS and runs setup
	$(MAKE) setup

#######################################
# Backup Target
#######################################
backup: ## Backup dotfiles (.zshrc, .tmux.conf, .gitignore, .gitconfig)
	$(call log_info,"Backing up files")
	@if [ -f $(HOME)/.zshrc ]; then cp $(HOME)/.zshrc $(HOME)/.zshrc.$(shell date +%Y%m%d).BAK; fi
	@if [ -f $(HOME)/.tmux.conf ]; then cp $(HOME)/.tmux.conf $(HOME)/.tmux.conf.$(shell date +%Y%m%d).BAK; fi
	@if [ -f $(HOME)/.gitignore ]; then cp $(HOME)/.gitignore $(HOME)/.gitignore.$(shell date +%Y%m%d).BAK; fi
	@if [ -f $(HOME)/.gitconfig ]; then cp $(HOME)/.gitconfig $(HOME)/.gitconfig.$(shell date +%Y%m%d).BAK; fi

#######################################
# Setup Target
#######################################
setup: backup ## Detect OS and run the appropriate setup
	$(call log_info,"Detecting operating system")
	@if [ "$(UNAME_S)" = "Darwin" ]; then
		$(MAKE) mac_setup
	elif [ "$(UNAME_S)" = "Linux" ]; then
		if grep -q "ID=debian" /etc/os-release; then
			$(MAKE) debian_setup
		elif grep -q "ID=rhel" /etc/os-release; then
			$(MAKE) rhel_setup
		else
			@echo "Unsupported Linux distribution."
			exit 1
		fi
	elif [ "$(OS)" = "Windows_NT" ]; then
		$(MAKE) windows_setup
	else
		@echo "Unsupported operating system."
		exit 1
	fi

#######################################
# Setup for Mac
#######################################
mac_setup: backup ## Configure environment for macOS
	$(call log_info,"Setting up for Mac")
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

#######################################
# Setup for Debian
#######################################
debian_setup: backup ## Configure environment for Debian-based systems
	$(call log_info,"Setting up for Debian")
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

#######################################
# Setup for RHEL
#######################################
rhel_setup: backup ## Configure environment for RHEL-based systems
	$(call log_info,"Setting up for RHEL")
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

#######################################
# Setup for Windows
#######################################
windows_setup: backup ## Configure environment for Windows
	$(call log_info,"Setting up for Windows")
	cp -r powershell_config $(USERPROFILE)
	PowerShell -Command "Start-Process -Verb RunAs -FilePath $(USERPROFILE)\powershell_config\windows_utils.ps1"
