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

## Execution Instructions on Development Server

Follow these steps to run this setup script on your development server:

1. SSH into your development server.

2. If Git is not installed, install it:
   ```
   sudo apt update
   sudo apt install git
   ```

3. Clone this repository:
   ```
   git clone https://github.com/takaeda/debian-neovim-setup.git
   cd debian-neovim-setup
   ```

4. Make the script executable:
   ```
   chmod +x setup-dev-env.sh
   ```

5. Run the script:
   ```
   ./setup-dev-env.sh
   ```

6. Follow the prompts to input necessary information and select installation options.

7. After installation is complete, start a new terminal session or reload your shell configuration file:
   ```
   source ~/.bashrc  # or ~/.zshrc (depending on your shell)
   ```

8. Launch Neovim and run the health check:
   ```
   nvim
   :checkhealth
   ```

## Note

- This script requires sudo privileges to install packages and modify system files.
- Existing configuration files will be backed up before modification.
- After running the script, launch Neovim and run `:checkhealth` to ensure all dependencies are correctly installed.
- While this script is designed for Debian-based systems, it may require modifications for non-Ubuntu distributions. Please report any issues you encounter on other systems.
- This script is designed to work on Debian-based Linux distributions (e.g., Ubuntu, Debian).
- To re-run the script, use the `--force` option:
  ```
  ./setup-dev-env.sh --force
  ```
- To use GitHub Copilot, run `:Copilot auth` in Neovim and complete the authentication process.

If you encounter any issues during installation, please report them in the Issues section of this repository.

## Contributing

Contributions are welcome! If you've tested this on other Debian-based distributions or have improvements to suggest, please feel free to submit a Pull Request or open an Issue.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
