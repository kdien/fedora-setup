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
ln -sf $HOME/dotfiles/powershell $HOME/.config/powershell

# Configure GNOME settings
if [[ "$XDG_CURRENT_DESKTOP" == *GNOME* ]]; then
    sudo dnf install gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator -y
    ./config-gnome.sh
    mkdir -p $HOME/bin
    for file in $HOME/dotfiles/gnome/*; do
        ln -sf "$file" $HOME/bin/"${file##/*}"
    done
fi

# Install Meslo fonts
mkdir -p $HOME/.fonts/meslo-nf
cp $HOME/dotfiles/fonts/Meslo*.ttf $HOME/.fonts/meslo-nf

# Symlink fontconfig
rm -rf $HOME/.config/fontconfig
ln -s $HOME/dotfiles/fontconfig $HOME/.config/fontconfig

# Enable additional repos
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
dnf check-update

# Remove bloat
sudo dnf remove $(cat ./pkg.remove) -y

# Install packages from repo
sudo dnf install $(cat ./pkg.add) -y

# Install Firefox from Mozilla
curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-CA" -o $HOME/Downloads/firefox.tar.bz2
tar -xvjf $HOME/Downloads/firefox.tar.bz2
sudo rm -rf /opt/firefox
sudo mv firefox /opt/firefox
sudo mkdir -p /usr/local/bin
sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
sudo install -o root -g root -m 644 firefox.desktop /usr/share/applications/firefox.desktop
rm -f $HOME/Downloads/firefox.tar.bz2

# Install Brave browser
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install brave-browser -y

# Install MS Edge
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge.repo
dnf check-update
sudo dnf install microsoft-edge-stable -y

# Install Google Chrome
sudo dnf install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -y
# Override default desktop entry to enable dark mode
sudo install -o root -g root -m 644 google-chrome.desktop /usr/local/share/applications/google-chrome.desktop

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
if command -v nautilus &> /dev/null; then
    sudo dnf install insync-nautilus -y
fi

# Install Viber
sudo dnf install https://download.cdn.viber.com/desktop/Linux/viber.rpm -y

# Install Zoom
sudo dnf install https://zoom.us/client/latest/zoom_x86_64.rpm -y

# Adobe Reader through Wine
export WINEARCH=win32
winetricks atmlib
winetricks riched20
winetricks wsh57
winetricks mspatcha
sudo mkdir -p /usr/share/fonts/segoe-ui
sudo cp $HOME/dotfiles/fonts/segoeui*.ttf /usr/share/fonts/segoe-ui/
curl -kL http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/1901020099/AcroRdrDC1901020099_en_US.exe -o $HOME/Downloads/adobereader.exe
wine $HOME/Downloads/adobereader.exe
echo 'After installing Adobe Reader, disable auto updates through Regedit, HKEY_LOCAL_MACHINE\Software\Adobe\Adobe ARM\Legacy\Reader\{key} and set Mode=0'

