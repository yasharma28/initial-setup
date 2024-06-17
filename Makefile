# Detect the operating system
UNAME_S := $(shell uname -s)

# Default target
.PHONY: all
all: setup

#######################################
# Display help information.
# Outputs:
#   Output to STDOUT.
#######################################
.PHONY: help
help:
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "A set of utility functions to setup/run programs smoothly."
	@echo ""
	@echo "Targets:"
	@echo "  all                 Default target, detects OS and runs the corresponding setup."
	@echo "  help                Display this help message."
	@echo "  mac_setup           Setup configuration for macOS."
	@echo "  debian_setup        Setup configuration for Debian."
	@echo "  rhel_setup          Setup configuration for RHEL."
	@echo "  windows_setup       Setup configuration for Windows."
	@echo ""
	@echo "Examples:"
	@echo "  make all            Run the default target."
	@echo "  make mac_setup      Run the macOS setup."
	@echo "  make debian_setup   Run the Debian setup."
	@echo "  make rhel_setup     Run the RHEL setup."
	@echo "  make windows_setup  Run the Windows setup."

#######################################
# Check for the operating system and call the respective setup function.
#######################################
.PHONY: setup
setup:
ifeq ($(UNAME_S), Darwin)
	@$(MAKE) mac_setup
else ifeq ($(UNAME_S), Linux)
	@if grep -q "ID=debian" /etc/os-release; then \
		$(MAKE) debian_setup; \
	elif grep -q "ID=rhel" /etc/os-release; then \
		$(MAKE) rhel_setup; \
	fi
else ifeq ($(OS), Windows_NT)
	@$(MAKE) windows_setup
endif

#######################################
# Setup for Mac
#######################################
.PHONY: mac_setup
mac_setup:
	@echo "Setting up for Mac..."
	cp -r aws $(HOME)/.aws
	cp -r brew $(HOME)/.brew
	cp -r ssh $(HOME)/.ssh
	mkdir -p $(HOME)/.config/nvim && cp -r nvim/* $(HOME)/.config/nvim/
	cp -r vim $(HOME)/.vim
	@if [ -f $(HOME)/.zshrc ]; then \
		cat zsh_config/.zshrc >> $(HOME)/.zshrc; \
	else \
		cp zsh_config/.zshrc $(HOME)/.zshrc; \
	fi
	cp zsh_config/tmux.conf.local $(HOME)/.tmux.conf
	cp .gitignore $(HOME)/.gitignore
	cp .gitconfig $(HOME)/.gitconfig
	./scripts/mac_utils.sh -i
	./scripts/mac_utils.sh -a

#######################################
# Setup for Debian
#######################################
.PHONY: debian_setup
debian_setup:
	@echo "Setting up for Debian..."
	cp -r aws $(HOME)/.aws
	cp -r ssh $(HOME)/.ssh
	mkdir -p $(HOME)/.config/nvim && cp -r nvim/* $(HOME)/.config/nvim/
	cp -r vim $(HOME)/.vim
	@if [ -f $(HOME)/.zshrc ]; then \
		cat zsh_config/.zshrc >> $(HOME)/.zshrc; \
	else \
		cp zsh_config/.zshrc $(HOME)/.zshrc; \
	fi
	cp zsh_config/tmux.conf.local $(HOME)/.tmux.conf
	cp .gitignore $(HOME)/.gitignore
	cp .gitconfig $(HOME)/.gitconfig
	./scripts/debian_utils.sh -u

#######################################
# Setup for RHEL
#######################################
.PHONY: rhel_setup
rhel_setup:
	@echo "Setting up for RHEL..."
	cp -r aws $(HOME)/.aws
	cp -r ssh $(HOME)/.ssh
	mkdir -p $(HOME)/.config/nvim && cp -r nvim/* $(HOME)/.config/nvim/
	cp -r vim $(HOME)/.vim
	@if [ -f $(HOME)/.zshrc ]; then \
		cat zsh_config/.zshrc >> $(HOME)/.zshrc; \
	else \
		cp zsh_config/.zshrc $(HOME)/.zshrc; \
	fi
	cp zsh_config/tmux.conf.local $(HOME)/.tmux.conf
	cp .gitignore $(HOME)/.gitignore
	cp .gitconfig $(HOME)/.gitconfig
	./scripts/rhel_utils.sh -u

#######################################
# Setup for Windows
#######################################
.PHONY: windows_setup
windows_setup:
	@echo "Setting up for Windows..."
	cp -r powershell_config $(USERPROFILE)
	PowerShell -Command "Start-Process -Verb RunAs -FilePath $(USERPROFILE)\powershell_config\windows_utils.ps1"
