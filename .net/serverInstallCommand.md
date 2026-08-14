# 1. Update package lists
sudo apt update && sudo apt install -y wget

# 2. Add Microsoft package repository (For Ubuntu 22.04 / 24.04)
# 1. Get your Ubuntu release version string (e.g., 22.04 or 24.04)
VERSION=$(lsb_release -rs)

# 2. Download the package using that variable
wget "https://packages.microsoft.com/config/ubuntu/${VERSION}/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb

wget "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# 3. Update repositories and install ASP.NET Core Runtime (replace 8.0 with your .NET version, e.g., 9.0)
sudo apt update
sudo apt uninstall -y aspnetcore-runtime-8.0


# Install .net 9.0
# 1. Download the official installer script
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh

# 2. Install .NET 9 Runtime system-wide
sudo ./dotnet-install.sh --version 9.0.0 --runtime aspnetcore --install-dir /usr/share/dotnet

# 3. Create a symbolic link so `dotnet` works everywhere
sudo ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet

# 4. Clean up script
rm dotnet-install.sh