#!/usr/bin/bash

# Get pureline bash prompt
git clone https://github.com/chris-marsh/pureline.git $HOME/pureline

# Setup bash symlinks
[[ -f $HOME/.bashrc ]] && mv $HOME/.bashrc $HOME/.bashrc.bak
ln -sf $HOME/fedora-setup/bash/.bashrc $HOME/.bashrc
ln -sf $HOME/fedora-setup/bash/.bash_aliases $HOME/.bash_aliases
ln -sf $HOME/fedora-setup/bash/.bash_functions $HOME/.bash_functions

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git $HOME/dotfiles
ln -sf $HOME/dotfiles/tmux/.tmux.conf $HOME/.tmux.conf
ln -sf $HOME/dotfiles/vim/.vimrc $HOME/.vimrc
ln -sf $HOME/dotfiles/alacritty $HOME/.config/alacritty
ln -sf $HOME/dotfiles/pureline/.pureline.conf $HOME/.pureline.conf

# Configure GNOME settings
if [[ "$XDG_CURRENT_DESKTOP" == *GNOME* ]]; then
    sudo dnf install gnome-tweaks gnome-extensions-app -y
    ./config-gnome.sh
    mkdir -p $HOME/bin
    for file in $HOME/dotfiles/gnome/*; do
        ln -sf "$file" $HOME/bin/"${file##/*}"
    done
fi

# Extract Meslo fonts
mkdir -p $HOME/.fonts/meslo-nf
tar -xzvf meslo-nf.tar.gz -C $HOME/.fonts/meslo-nf

# Symlink fontconfig
rm -rf $HOME/.config/fontconfig
ln -s $HOME/dotfiles/fontconfig $HOME/.config/fontconfig

# Enable additional repos
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf copr enable dawid/better_fonts -y
sudo dnf copr enable pschyska/alacritty -y
dnf check-update

# Remove bloat
sudo dnf remove $(cat ./pkg.remove) -y

# Install packages from repo
sudo dnf install $(cat ./pkg.add) -y

# Install MS Edge
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge-dev.repo
dnf check-update
sudo dnf install microsoft-edge-dev -y

# Install Google Chrome
sudo dnf install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -y

# Add VS Code repo and install
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" | sudo tee /etc/yum.repos.d/vscode.repo
dnf check-update
sudo dnf install code -y

# Install PowerShell Core
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
dnf check-update
sudo dnf install powershell -y

# Add Insync repo and install
sudo rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
echo -e "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/$(rpm -E %fedora)/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nenabled=1\nmetadata_expire=120m\n" | sudo tee /etc/yum.repos.d/insync.repo
dnf check-update
sudo dnf install insync -y

# Install Viber
sudo dnf install https://download.cdn.viber.com/desktop/Linux/viber.rpm -y

# Install Zoom
sudo dnf install https://zoom.us/client/latest/zoom_x86_64.rpm -y

