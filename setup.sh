#!/bin/bash
set -euo pipefail

if [ "$USER" != "root" ]; then
    echo "Please run this as root or with sudo"
    exit 2
fi

echo "Setting up Debian..."

echo "What is the username to configure?"
read -r name
HOME="/home/$name"

# Add user to sudo
usermod -aG sudo "$name"

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
nala install dirmngr ca-certificates software-properties-common apt-transport-https curl build-essential -y

# Determine if laptop
chassis=$(dmidecode -s chassis-type)

if [[ $chassis == 'Notebook' ]]; then
    echo "Laptop detected! Installing thermald and auto-cpufreq"
    # Install thermald
    nala install thermald -y
    systemctl enable thermald

    # Install auto-cpufreq
    mkdir -p /home/$name/Git/auto-cpufreq
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git /home/$name/Git/auto-cpufreq
    sh /home/$name/Git/auto-cpufreq/auto-cpufreq-installer --install
    auto-cpufreq --install
    chown -R "$name":"$name" "$HOME"/Git/auto-cpufreq
fi

# vscode repo
echo "Installing VSCode"
curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/vscode.gpg >/dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main' | tee /etc/apt/sources.list.d/vscode.list

# Microsoft Edge Stable repo
echo "Installing Microsoft Edge Stable"
curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/microsoft-edge.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | tee /etc/apt/sources.list.d/microsoft-edge.list

# Google Chrome repo
echo "Installing Google Chrome"
curl -fSsl https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list

# Install packages
nala update
nala install google-chrome-stable microsoft-edge-stable code -y

# Install NVIDIA drivers
echo "Installing NVIDIA drivers"
curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub | gpg --dearmor | tee /usr/share/keyrings/nvidia-drivers.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64 /" | tee /etc/apt/sources.list.d/nvidia-drivers.list
nala update && nala install nvidia-driver -y
nala install nvidia-driver-libs:i386 -y

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

# Pyenv
nala install libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

export PYENV_ROOT="/home/$name/.pyenv"
curl https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >>"$HOME"/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>"$HOME"/.bashrc
echo 'eval "$(pyenv init -)"' >>"$HOME"/.bashrc

# Correct permissions on pyenv directory
chown -R "$name":"$name" "$HOME"/.pyenv

# Install fonts
nala install fonts-firacode -y

# Install Meslo Nerd Font
echo "Installing Meslo Nerd Font"
mkdir -p "$HOME/.local/share/fonts"
curl -fSsL 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf' -o "$HOME/.local/share/fonts/MesloLGS NF Regular.ttf"

# Install Flatpak
nala install flatpak plasma-discover-backend-flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install pipewire
nala install pipewire-audio -y

# Install firewalld and firewall-config
nala install firewalld firewall-config -y

echo "Done! Rebooting in 10 seconds..."
sleep 10
reboot
