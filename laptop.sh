#!/bin/bash
set -euo pipefail

if [ "$USER" != "root" ]; then
    echo "Please run this as root or with sudo"
    exit 2
fi

echo "Setting up Debian laptop..."
# Add user to sudo
usermod -aG sudo alex

# Add contrib and non-free to sources.list
sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list

# Add bookworm-backports to sources.list
echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" | tee /etc/apt/sources.list.d/backports.list

# Add i386 architecture
dpkg --add-architecture i386

# Install nala
apt update && apt install nala -y

# Upgrade
nala upgrade -y

# Install utils
nala install dirmngr ca-certificates software-properties-common apt-transport-https curl -y

# Install thermald and power-profiles-daemon
nala install thermald power-profiles-daemon -y
systemctl enable thermald

# Install vscode
echo "Installing VSCode"
curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg >/dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main' | tee /etc/apt/sources.list.d/vscode.list
nala update && nala install code -y

# Install Microsoft Edge Stable
echo "Installing Microsoft Edge Stable"
curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/microsoft-edge.gpg >/dev/null
echo "deb [arch=amd64] signed-by=/usr/share/keyrings/microsoft-edge.gpg https://packages.microsoft.com/repos/edge stable main" | tee /etc/apt/sources.list.d/microsoft-edge.list
nala update && nala install microsoft-edge-stable -y

# Install Google Chrome
curl -fSsl https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
nala update && nala install google-chrome-stable -y

# Install NVIDIA drivers
curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/3bf863cc.pub | gpg --dearmor | tee /usr/share/keyrings/nvidia-drivers.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64 /" | tee /etc/apt/sources.list.d/nvidia-drivers.list
nala update && nala install nvidia-driver -y
nala install install nvidia-driver-libs:i386 -y

# Install Insync
echo "Installing Insync"
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
echo "deb http://apt.insync.io/debian bookworm non-free contrib" | tee /etc/apt/sources.list.d/insync.list
nala update && nala install insync -y
nala update && nala install insync-dolphin -y

# Install Steam
echo "Installing Steam"
nala install steam-installer -y

# Removing Firefox and libreoffice
nala purge libreoffice* firefox* -y
nala autoremove -y

echo "Done! Rebooting in 10 seconds..."
sleep 10
reboot
