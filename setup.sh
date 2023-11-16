#!/usr/bin/env bash

# Source bash config
cat >> "$HOME/.bashrc" <<'EOF'
[[ -f "$HOME/dotfiles/bash/.bash_common" ]] && . "$HOME/dotfiles/bash/.bash_common"
EOF

# Clone dotfiles and setup symlinks
git clone https://github.com/kdien/dotfiles.git "$HOME/dotfiles"
configs=(
    alacritty
    fontconfig
    nvim
    powershell
    tmux
    wezterm
)
for config in "${configs[@]}"; do
    ln -sf "$HOME/dotfiles/$config" "$HOME/.config/$config"
done

# Configure GNOME settings
if command -v gnome-shell &>/dev/null; then
    sudo dnf install -y gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator
    ./config-gnome.sh
    mkdir -p "$HOME/bin"
    for file in "$HOME"/dotfiles/gnome/*; do
        ln -sf "$file" "$HOME/bin/$(basename "$file")"
    done
fi

# Install fonts
for font in meslo meslo-nf; do
    tar -xf "$HOME/dotfiles/fonts/$font.tar.gz"
    sudo chown root:root ./*.ttf
    sudo mkdir -p "/usr/share/fonts/$font"
    sudo mv ./*.ttf "/usr/share/fonts/$font"
done

curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz -o nf-symbols.tar.xz
tar -xf nf-symbols.tar.xz --wildcards '*.ttf'
sudo chown root:root ./*.ttf
sudo mkdir -p /usr/share/fonts/nf-symbols
sudo mv ./*.ttf /usr/share/fonts/nf-symbols
rm -f nf-symbols.tar.xz

curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraMono.tar.xz -o fira-mono-nf.tar.xz
tar -xf fira-mono-nf.tar.xz --wildcards 'FiraMonoNerdFont-*.otf'
sudo chown root:root ./*.otf
sudo mkdir -p /usr/share/fonts/fira-mono-nf
sudo mv ./*.otf /usr/share/fonts/fira-mono-nf
rm -f fira-mono-nf.tar.xz

# Enable additional repos
sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf config-manager -y --add-repo "https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo"

# Remove bloat
sudo dnf remove -y $(cat ./pkg.remove)

# Install packages from repo
sudo dnf install -y $(cat ./pkg.add) --exclude $(cat ./pkg.exclude)

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
tar -xvjf "$HOME/Downloads/firefox.tar.bz2"
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
# Override default desktop entry to enable dark mode
sudo install -o root -g root -m 644 desktop-entries/google-chrome.desktop /usr/local/share/applications/google-chrome.desktop

# Install tfenv and Terraform
git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
"$HOME/.tfenv/bin/tfenv" install latest
"$HOME/.tfenv/bin/tfenv" use latest

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
curl https://download.cdn.viber.com/desktop/Linux/viber.AppImage -o "$HOME/Downloads/viber.AppImage"
chmod +x "$HOME/Downloads/viber.AppImage"
sudo install -o root -g root -m 755 "$HOME/Downloads/viber.AppImage" /opt/viber/
sudo install -o root -g root -m 644 viber.png /opt/viber/
sudo install -o root -g root -m 644 desktop-entries/viber.desktop /usr/share/applications/viber.desktop
rm -f "$HOME/Downloads/viber.AppImage"

# Install Zoom
sudo dnf install -y https://zoom.us/client/latest/zoom_x86_64.rpm

# Install WezTerm
sudo dnf install -y "$(curl -sSL -H 'Accept: application/vnd.github+json' https://api.github.com/repos/wez/wezterm/releases/latest | jq -r ".assets[] | select(.browser_download_url | match(\"fedora$(rpm -E %fedora).*rpm$\")) | .browser_download_url")"
