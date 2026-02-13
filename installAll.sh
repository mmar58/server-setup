#!/bin/sh

# Configuration: Set to true to install, false to skip
UPDATE_SYSTEM=true
INSTALL_NODE=true      # Node.js 24.x & NPM
INSTALL_TOOLS=true     # pnpm and pm2
INSTALL_MARIADB=false
INSTALL_NGINX=true

# Exit on error
set -e

echo "🚀 Starting server setup..."

# 1. Update System
if [ "$UPDATE_SYSTEM" = true ]; then
    echo "🔄 Updating System..."
    sudo apt update && sudo apt upgrade -y
else
    echo "⏭️ Skipping System Update"
fi

# 2. Install Node.js 24.x LTS & NPM
if [ "$INSTALL_NODE" = true ]; then
    echo "📦 Installing Node.js 24.x..."
    # Using NodeSource distribution
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "⏭️ Skipping Node.js Installation"
fi

# 3. Install pnpm and pm2
if [ "$INSTALL_TOOLS" = true ]; then
    echo "⚙️ Installing pnpm and pm2..."
    sudo npm install -g pnpm pm2
else
    echo "⏭️ Skipping pnpm and pm2 Installation"
fi

# 4. Install MariaDB
if [ "$INSTALL_MARIADB" = true ]; then
    echo "🗄️ Installing MariaDB..."
    sudo apt install -y mariadb-server
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
else
    echo "⏭️ Skipping MariaDB Installation"
fi

# 5. Install Nginx
if [ "$INSTALL_NGINX" = true ]; then
    echo "🌐 Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
else
    echo "⏭️ Skipping Nginx Installation"
fi

# 6. Verify Installations
echo "✅ Verification:"

if command -v node > /dev/null 2>&1; then echo "Node: $(node -v)"; else echo "Node: Not installed"; fi
if command -v npm > /dev/null 2>&1; then echo "npm: $(npm -v)"; else echo "npm: Not installed"; fi
if command -v pnpm > /dev/null 2>&1; then echo "pnpm: $(pnpm -v)"; else echo "pnpm: Not installed"; fi
if command -v pm2 > /dev/null 2>&1; then echo "pm2: $(pm2 -v)"; else echo "pm2: Not installed"; fi
if command -v nginx > /dev/null 2>&1; then echo "nginx: $(nginx -v)"; else echo "nginx: Not installed"; fi
if command -v mariadb > /dev/null 2>&1; then echo "mariadb: $(mariadb --version)"; else echo "mariadb: Not installed"; fi

echo "🎉 Setup complete! Don't forget to run 'sudo mysql_secure_installation' to secure your database."