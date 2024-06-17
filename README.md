# initial-setup

This repository contains configuration files and utility scripts to set up and maintain a consistent development environment across different operating systems, including macOS, Debian, RHEL, and Windows.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Targets](#targets)
  - [Help](#help)
- [Configuration Details](#configuration-details)
  - [Git Configuration](#git-configuration)
  - [AWS Configuration](#aws-configuration)
  - [Editor Configuration](#editor-configuration)
  - [Shell Configuration](#shell-configuration)
- [Scripts](#scripts)
- [License](#license)
- [Contributing](#contributing)
- [Issues](#issues)
- [Contact](#contact)

## Repository Structure

```sh
.
├── .github
│   ├── CODEOWNERS
│   └── workflows
│       └── dependabot.yml
├── aws
│   ├── config
│   └── credentials
├── brew
│   └── Brewfile
├── nvim
│   ├── after
│   │   └── plugin
│   │       ├── colors.lua
│   │       ├── fugitive.lua
│   │       ├── harpoon.lua
│   │       ├── lsp.lua
│   │       ├── telescope.lua
│   │       ├── tresitter.lua
│   │       └── undotree.lua
│   ├── lua
│   │   └── nvimrc
│   │       ├── init.lua
│   │       ├── packer.lua
│   │       ├── remap.lua
│   │       └── set.lua
│   ├── plugin
│   │   └── packer_compiled.lua
│   └── init.lua
├── powershell_config
│   ├── Microsoft.PowerShell_profile.ps1
│   ├── oh-my-posh_default.yaml
│   └── packages_windows.json
├── scripts
│   ├── debian_utils.sh
│   ├── mac_utils.sh
│   ├── rhel_utils.sh
│   └── windows_utils.ps1
├── ssh
│   └── config
├── vim
│   ├── autoload
│   ├── backup
│   ├── colors
│   ├── plugged
│   └── .vimrc
├── zsh_config
│   ├── .zshrc
│   ├── install.txt
│   ├── iterm_yash_personal.json
│   └── tmux.conf.local
├── .gitconfig
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

## Getting Started

### Prerequisites

- Ensure you have the necessary permissions to run the scripts and copy files to the required locations.
- For macOS, install Homebrew if it is not already installed.
- For Debian and RHEL, ensure you have root access or sudo privileges.
- For Windows, ensure you can run PowerShell scripts as an administrator.

### Setup

To set up your development environment, navigate to the root of this repository and run:

```sh
make
```

This command will detect your operating system and run the appropriate setup targets.

### Targets

You can also run specific targets based on your operating system:

- **macOS**:
  ```sh
  make mac_setup
  ```

- **Debian**:
  ```sh
  make debian_setup
  ```

- **RHEL**:
  ```sh
  make rhel_setup
  ```

- **Windows**:
  ```sh
  make windows_setup
  ```

### Help

For more information on the available targets and their usage, run:

```sh
make help
```

## Configuration Details

### Git Configuration

The repository includes `.gitconfig` and `.gitignore` files to standardize your Git configuration and ignore patterns across different projects.

### AWS Configuration

The `aws` directory contains example configuration files for AWS credentials and configuration. These files will be copied to `~/.aws` during the setup process.

### Editor Configuration

The repository includes configuration files for various editors:

- **Neovim**: Configuration files in the `nvim` directory.
- **Vim**: Configuration files in the `vim` directory.

### Shell Configuration

- **Zsh**: The `zsh_config` directory contains `.zshrc` and other Zsh-related configuration files.

## Scripts

The `scripts` directory contains utility scripts to automate various setup tasks:

- **mac_utils.sh**: Utility script for macOS.
- **debian_utils.sh**: Utility script for Debian.
- **rhel_utils.sh**: Utility script for RHEL.
- **windows_utils.ps1**: PowerShell script for Windows.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## Issues

If you encounter any issues, please create a new issue in the repository's [issue tracker](https://github.com/yasharma28/initial-setup/issues).

## Contact

For questions or feedback, please contact [Yash Sharma](mailto:yasharma28@gmail.com).
