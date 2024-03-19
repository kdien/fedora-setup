#!/usr/bin/env bash

# Source bash config
cat >>"$HOME/.bashrc" <<'EOF'
[[ -f "$HOME/dotfiles/bash/.bash_common" ]] && . "$HOME/dotfiles/bash/.bash_common"
EOF

# SSH agent for KDE
if command -v ksshaskpass &>/dev/null; then
  mkdir -p "$HOME/.local/bin"
  script_path="$HOME/.local/bin/add_ssh_key_to_agent.sh"

  echo "SSH_ASKPASS=$(command -v ksshaskpass) $(command -v ssh-add) </dev/null" >"$script_path"

  mkdir -p "$HOME/.config/autostart"
  cat >"$HOME/.config/autostart/ssh.desktop" <<EOF
[Desktop Entry]
Exec=$script_path
Icon=dialog-scripts
Name=$(basename "$script_path")
Type=Application
X-KDE-AutostartScript=true
EOF
fi

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git "$HOME/dotfiles"
configs=(
  alacritty
  nvim
  powershell
  tmux
  wezterm
)
for config in "${configs[@]}"; do
  ln -sf "$HOME/dotfiles/$config" "$HOME/.config/$config"
done

# Copy base git config
cp "$HOME/dotfiles/git/config" "$HOME/.gitconfig"

# Configure GNOME settings
if command -v gnome-shell &>/dev/null; then
  sudo dnf install -y gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator
  ./config-gnome.sh
  mkdir -p "$HOME/bin"
  for file in "$HOME"/dotfiles/gnome/*; do
    ln -sf "$file" "$HOME/bin/$(basename "$file")"
  done
fi

# Cursor theme fix for Chromium-based browsers on KDE Plasma
if command -v plasmashell &>/dev/null; then
  mkdir -p "$HOME/.local/share/icons/default"
  echo -e '[icon theme]\nInherits=breeze_cursors' >>"$HOME/.local/share/icons/default/index.theme"
fi

# Install fonts
for font in "$HOME"/dotfiles/fonts/*.tar.gz; do
  name=$(basename "$font" | cut -d '.' -f 1)
  dest="$HOME/.local/share/fonts/$name"
  mkdir -p "$dest"
  tar -xf "$font" --directory="$dest"
done

# Enable additional repos
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Remove bloat
sudo dnf remove -y $(cat ./pkg.remove)

# Install packages from repo
sudo dnf install -y $(cat ./pkg.add)

# Set up interception-tools
git clone https://gitlab.com/interception/linux/tools.git interception-tools
cd interception-tools || return
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cp build/{intercept,mux,udevmon,uinput} /usr/local/bin
sed -i 's|/usr/bin/udevmon|/usr/local/bin/udevmon|' udevmon.service
sudo cp udevmon.service /usr/lib/systemd/system
sudo systemctl daemon-reload
cd ..
rm -rf interception-tools

# Set up caps2esc
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
curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-CA" -o "$HOME/Downloads/firefox.tar.bz2"
tar -xf "$HOME/Downloads/firefox.tar.bz2"
sudo rm -rf /opt/firefox
sudo mv firefox /opt/firefox
sudo mkdir -p /usr/local/bin
sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
sudo install -o root -g root -m 644 desktop-entries/firefox.desktop /usr/share/applications/firefox.desktop
rm -f "$HOME/Downloads/firefox.tar.bz2"
echo MOZ_ENABLE_WAYLAND=1 | sudo tee -a /etc/environment

# Install Brave browser
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install -y brave-browser

# Install Google Chrome
sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

# Install tfenv and Terraform
git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
"$HOME/.tfenv/bin/tfenv" install latest
"$HOME/.tfenv/bin/tfenv" use latest

# Environment variables for HiDPI for Qt apps
sudo tee -a /etc/environment <<EOF
QT_AUTO_SCREEN_SCALE_FACTOR=1
QT_ENABLE_HIGHDPI_SCALING=1
EOF

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
for filemgr in nautilus dolphin; do
  if command -v "$filemgr" &>/dev/null; then
    sudo dnf install -y insync-"$filemgr"
  fi
done

# Install Zoom
sudo dnf install -y https://zoom.us/client/latest/zoom_x86_64.rpm

# Install WezTerm
sudo dnf install -y "$(curl -sSL -H 'Accept: application/vnd.github+json' https://api.github.com/repos/wez/wezterm/releases/latest | jq -r ".assets[] | select(.browser_download_url | match(\"fedora$(rpm -E %fedora).*rpm$\")) | .browser_download_url")"
