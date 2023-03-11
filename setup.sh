#!/usr/bin/env bash

# Setup bash symlinks
[[ -f "$HOME"/.bashrc ]] && mv "$HOME"/.bashrc "$HOME"/.bashrc.bak
ln -sf "$HOME"/fedora-setup/.bashrc "$HOME"/.bashrc

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git "$HOME"/dotfiles
ln -sf "$HOME"/dotfiles/shell/.profile "$HOME"/.profile
ln -sf "$HOME"/dotfiles/tmux/.tmux.conf "$HOME"/.tmux.conf
ln -sf "$HOME"/dotfiles/neovim "$HOME"/.config/nvim
ln -sf "$HOME"/dotfiles/kitty "$HOME"/.config/kitty
ln -sf "$HOME"/dotfiles/pureline/.pureline.conf "$HOME"/.pureline.conf
ln -sf "$HOME"/dotfiles/powershell "$HOME"/.config/powershell

# Configure GNOME settings
if [[ "$XDG_CURRENT_DESKTOP" == *GNOME* ]]; then
    sudo dnf install gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator -y
    ./config-gnome.sh
    mkdir -p "$HOME"/bin
    for file in "$HOME"/dotfiles/gnome/*; do
        ln -sf "$file" "$HOME/bin/${file##/*}"
    done
fi

# Install Meslo fonts
sudo mkdir -p /usr/share/fonts/meslo-nf
sudo cp "$HOME"/dotfiles/fonts/Meslo*.ttf "$HOME"/.fonts/meslo-nf

# Symlink fontconfig
rm -rf "$HOME"/.config/fontconfig
ln -s "$HOME"/dotfiles/fontconfig "$HOME"/.config/fontconfig

# Enable additional repos
sudo dnf install "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" -y
dnf check-update

# Remove bloat
sudo dnf remove "$(cat ./pkg.remove)" -y

# Install packages from repo
sudo dnf install "$(cat ./pkg.add)" -y

# Set up interception-tools and caps2esc
sudo dnf copr enable fszymanski/interception-tools -y
sudo dnf install interception-tools -y

git clone https://gitlab.com/interception/linux/plugins/caps2esc.git
cd caps2esc || return
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cp build/caps2esc /usr/local/bin
cd ..
rm -rf caps2esc

sudo mkdir -p /etc/interception/udevmon.d
sudo tee /etc/interception/udevmon.d/caps2esc.yaml <<'EOF'
- JOB: intercept -g $DEVNODE | caps2esc | uinput -d $DEVNODE
  DEVICE:
    EVENTS:
      EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    LINK: /dev/input/by-path/.*-event-kbd
EOF

sudo systemctl enable --now udevmon

# Install Firefox from Mozilla
curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-CA" -o "$HOME"/Downloads/firefox.tar.bz2
tar -xvjf "$HOME"/Downloads/firefox.tar.bz2
sudo rm -rf /opt/firefox
sudo mv firefox /opt/firefox
sudo mkdir -p /usr/local/bin
sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
sudo install -o root -g root -m 644 firefox.desktop /usr/share/applications/firefox.desktop
rm -f "$HOME"/Downloads/firefox.tar.bz2
echo MOZ_ENABLE_WAYLAND=1 | sudo tee -a /etc/environment

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

# Install tfenv and Terraform
git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME"/.tfenv
"$HOME"/.tfenv/bin/tfenv install latest
"$HOME"/.tfenv/bin/tfenv use latest

# Add Insync repo and install
sudo rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
echo -e "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/$(rpm -E %fedora)/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nenabled=1\nmetadata_expire=120m\n" | sudo tee /etc/yum.repos.d/insync.repo
dnf check-update
sudo dnf install insync -y
if command -v nautilus &> /dev/null; then
    sudo dnf install insync-nautilus -y
fi

# Install Viber
sudo rm -rf /opt/viber
sudo mkdir -p /opt/viber
curl https://download.cdn.viber.com/desktop/Linux/viber.AppImage -o "$HOME"/Downloads/viber.AppImage
chmod +x "$HOME"/Downloads/viber.AppImage
sudo install -o root -g root -m 755 "$HOME"/Downloads/viber.AppImage /opt/viber/
sudo install -o root -g root -m 644 viber.png /opt/viber/
sudo install -o root -g root -m 644 viber.desktop /usr/share/applications/viber.desktop
rm -f "$HOME"/Downloads/viber.AppImage

# Install Zoom
sudo dnf install https://zoom.us/client/latest/zoom_x86_64.rpm -y

# Adobe Reader through Wine
# export WINEARCH=win32
# winetricks atmlib
# winetricks riched20
# winetricks wsh57
# winetricks mspatcha
# sudo mkdir -p /usr/share/fonts/segoe-ui
# sudo cp "$HOME"/dotfiles/fonts/segoeui*.ttf /usr/share/fonts/segoe-ui/
# curl -kL http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/1901020099/AcroRdrDC1901020099_en_US.exe -o "$HOME"/Downloads/adobereader.exe
# wine "$HOME"/Downloads/adobereader.exe
# echo 'After installing Adobe Reader, disable auto updates through Regedit, HKEY_LOCAL_MACHINE\Software\Adobe\Adobe ARM\Legacy\Reader\{key} and set Mode=0'

