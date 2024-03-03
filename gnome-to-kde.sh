#!/usr/bin/env bash
sudo dnf shell -y --setopt protected_packages= << EOI
swap fedora-release-workstation fedora-release-kde
swap fedora-release-identity-workstation fedora-release-identity-kde
run
remove @gnome-desktop
run
remove *gnome* *gtk*
run
install @kde-desktop-environment
run
EOI
sudo systemctl restart sddm.service
EOF
