#!/usr/bin/bash

# Configure GNOME settings
./config-gnome.sh

# Setup bash symlinks
if [ -f ~/.bashrc ]; then
    mv ~/.bashrc ~/.bashrc.bak
fi
ln -s ~/fedora-setup/bash/.bashrc ~/.bashrc
ln -s ~/fedora-setup/bash/.bash_aliases ~/.bash_aliases
ln -s ~/fedora-setup/bash/.bash_functions ~/.bash_functions

# Enable additional repos
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf copr enable dawid/better_fonts -y
sudo dnf copr enable pschyska/alacritty -y
dnf check-update

# Remove bloat
sudo dnf remove $(cat ./pkg.remove) -y

# Install packages from repo
sudo dnf install $(cat ./pkg.add) -y

# Extract Meslo fonts
mkdir -p ~/.fonts/meslo-nf
tar -xzvf meslo-nf.tar.gz -C ~/.fonts/meslo-nf

# Create custom font config
mkdir -p ~/.config/fontconfig
cp fonts.conf ~/.config/fontconfig

# Install Google Chrome
sudo dnf install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -y

# Add VS Code repo and install
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" | sudo tee /etc/yum.repos.d/vscode.repo
dnf check-update
sudo dnf install code -y

# Install PowerShell Core
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
dnf check-update
sudo dnf install powershell -y

# Add Insync repo and install
sudo rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
echo -e "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/30/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nenabled=1\nmetadata_expire=120m\n" | sudo tee /etc/yum.repos.d/insync.repo
dnf check-update
sudo dnf install insync -y

# Install Viber
sudo dnf install https://download.cdn.viber.com/desktop/Linux/viber.rpm -y

