# Server Setup & Management Scripts 🚀

This repository contains scripts and tips to streamline the setup and management of Linux servers (specifically targeting Ubuntu/Debian environments).

## Available Scripts

### 1. `installAll.sh`
A comprehensive setup script that automates the installation of essential server components.

**Features:**
- Update System (apt)
- Install Node.js (v24.x LTS) & NPM
- Install pnpm & pm2
- Install MariaDB (optional)
- Install Nginx (optional)

**Usage:**
1.  **Clone the repository** (or download the script).
2.  **Make the script executable** (optional, you can also run with `sh`):
    ```bash
    chmod +x installAll.sh
    ```
3.  **Configure the script:**
    Open `installAll.sh` in a text editor and set the boolean flags at the top to `true` or `false` depending on your needs:
    ```bash
    # Configuration
    UPDATE_SYSTEM=true
    INSTALL_NODE=true
    INSTALL_TOOLS=true
    INSTALL_MARIADB=true  # Set to false to skip
    INSTALL_NGINX=true    # Set to false to skip
    ```
4.  **Run the script:**
    ```bash
    ./installAll.sh
    # OR
    sh installAll.sh
    ```

## Contributing
Feel free to add more scripts or tips to help manage servers more efficiently!
