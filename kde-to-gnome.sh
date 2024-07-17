#!/usr/bin/env bash
sudo dnf shell -y --setopt protected_packages= <<EOI
swap fedora-release-kde fedora-release-workstation
swap fedora-release-identity-kde fedora-release-identity-workstation
run
remove @kde-desktop-environment
run
remove plasma-desktop
run
install @gnome-desktop
run
EOI
sudo systemctl restart gdm.service
