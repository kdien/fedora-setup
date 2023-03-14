#!/usr/bin/env bash

# Source bash config
cat >> "$HOME"/.bashrc <<'EOF'
[[ -f "$HOME"/dotfiles/bash/.bash_common ]] && . "$HOME"/dotfiles/bash/.bash_common
EOF

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git "$HOME"/dotfiles
ln -sf "$HOME"/dotfiles/tmux/.tmux.conf "$HOME"/.tmux.conf
ln -sf "$HOME"/dotfiles/neovim "$HOME"/.config/nvim
ln -sf "$HOME"/dotfiles/alacritty "$HOME"/.config/alacritty
ln -sf "$HOME"/dotfiles/kitty "$HOME"/.config/kitty
ln -sf "$HOME"/dotfiles/powershell "$HOME"/.config/powershell

# Configure GNOME settings
if [[ "$XDG_CURRENT_DESKTOP" == *GNOME* ]]; then
    sudo dnf install -y gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator
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
sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Remove bloat
sudo dnf remove -y "$(cat ./pkg.remove)"

# Install packages from repo
sudo dnf install -y "$(cat ./pkg.add)"

# Set up interception-tools and caps2esc
sudo dnf copr enable -y fszymanski/interception-tools
sudo dnf install -y interception-tools

git clone https://gitlab.com/interception/linux/plugins/caps2esc.git
cd caps2esc || return
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cp build/caps2esc /usr/local/bin
cd ..
rm -rf caps2esc

sudo mkdir -p /etc/interception/udevmon.d
sudo install -o root -g root -m 644 caps2esc.yaml /etc/interception/udevmon.d/caps2esc.yaml
sudo systemctl enable --now udevmon

# Install Firefox from Mozilla
curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-CA" -o "$HOME"/Downloads/firefox.tar.bz2
tar -xvjf "$HOME"/Downloads/firefox.tar.bz2
sudo rm -rf /opt/firefox
sudo mv firefox /opt/firefox
sudo mkdir -p /usr/local/bin
sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
sudo install -o root -g root -m 644 desktop-entries/firefox.desktop /usr/share/applications/firefox.desktop
rm -f "$HOME"/Downloads/firefox.tar.bz2
echo MOZ_ENABLE_WAYLAND=1 | sudo tee -a /etc/environment

# Install Brave browser
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install -y brave-browser

# Install MS Edge
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge.repo
sudo dnf install -y microsoft-edge-stable

# Install Google Chrome
sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
# Override default desktop entry to enable dark mode
sudo install -o root -g root -m 644 desktop-entries/google-chrome.desktop /usr/local/share/applications/google-chrome.desktop

# Add VS Code repo and install
sudo tee /etc/yum.repos.d/vscode.repo <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf install -y code

# Install tfenv and Terraform
git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME"/.tfenv
"$HOME"/.tfenv/bin/tfenv install latest
"$HOME"/.tfenv/bin/tfenv use latest

# Add Insync repo and install
sudo rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
sudo tee /etc/yum.repos.d/insync.repo <<EOF
[insync]
name=Insync
baseurl=http://yum.insync.io/fedora/$(rpm -E %fedora)
gpgcheck=1
gpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
enabled=1
metadata_expire=120m
EOF
sudo dnf install -y insync
if command -v nautilus &> /dev/null; then
    sudo dnf install -y insync-nautilus
fi

# Install Viber
sudo rm -rf /opt/viber
sudo mkdir -p /opt/viber
curl https://download.cdn.viber.com/desktop/Linux/viber.AppImage -o "$HOME"/Downloads/viber.AppImage
chmod +x "$HOME"/Downloads/viber.AppImage
sudo install -o root -g root -m 755 "$HOME"/Downloads/viber.AppImage /opt/viber/
sudo install -o root -g root -m 644 viber.png /opt/viber/
sudo install -o root -g root -m 644 desktop-entries/viber.desktop /usr/share/applications/viber.desktop
rm -f "$HOME"/Downloads/viber.AppImage

# Install Zoom
sudo dnf install -y https://zoom.us/client/latest/zoom_x86_64.rpm

