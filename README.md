# Debian-based Neovim Setup

This repository contains a script to set up a development environment on Debian-based Linux distributions (such as Ubuntu, Debian, Linux Mint, etc.), focusing on Neovim, tmux, and related tools.

## Features

- Installs and configures Neovim with useful plugins
- Sets up tmux with a basic configuration
- Installs Node.js (optional)
- Configures Git and other essential development tools

## Compatibility

This script is designed to work on Debian-based Linux distributions that use the `apt` package manager. It has been tested on:

- Ubuntu
- Debian

It may also work on other Debian derivatives like Linux Mint or Elementary OS, but hasn't been extensively tested on these platforms.

## Usage

1. Clone this repository:
   ```
   git clone https://github.com/takaeda/debian-neovim-setup.git
   cd debian-neovim-setup
   ```

2. Make the script executable:
   ```
   chmod +x setup-dev-env.sh
   ```

3. Run the script with sudo privileges:
   ```
   sudo ./setup-dev-env.sh
   ```

4. Follow the on-screen prompts to complete the installation.

## Note

- This script requires sudo privileges to install packages and modify system files.
- Existing configuration files will be backed up before modification.
- After running the script, launch Neovim and run `:checkhealth` to ensure all dependencies are correctly installed.
- While this script is designed for Debian-based systems, it may require modifications for non-Ubuntu distributions. Please report any issues you encounter on other systems.

## Contributing

Contributions are welcome! If you've tested this on other Debian-based distributions or have improvements to suggest, please feel free to submit a Pull Request or open an Issue.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
