#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID != 0 ]]; then
  echo 'Run as root inside Dewford.' >&2
  exit 1
fi

# Install the multi-user daemon once. The archive is pinned and verified.
if [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  installer_dir=$(mktemp -d)
  trap 'rm -rf "$installer_dir"' EXIT
  archive=nix-2.34.6-x86_64-linux.tar.xz
  curl --fail --location --output "$installer_dir/$archive" \
    "https://releases.nixos.org/nix/nix-2.34.6/$archive"
  (
    cd "$installer_dir"
    echo "311b9f406f0239ef640a1e3fbea1df1bac9d3a7c316c4def30df3206dd964960  $archive" | sha256sum --check
    tar -xf "$archive"
    ./nix-2.34.6-x86_64-linux/install --daemon --yes
  )
fi

install -d -m 0755 /etc/nix
# Keep Ubuntu's system services native; Nix owns the user environment.
if ! grep -qx 'experimental-features = nix-command flakes' /etc/nix/nix.conf; then
  echo 'experimental-features = nix-command flakes' >>/etc/nix/nix.conf
fi
systemctl restart nix-daemon.service

if ! command -v tailscale >/dev/null; then
  install -d -m 0755 /usr/share/keyrings
  curl --fail --location --output /usr/share/keyrings/tailscale-archive-keyring.gpg \
    https://pkgs.tailscale.com/stable/ubuntu/stonking.noarmor.gpg
  echo 'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu stonking main' \
    >/etc/apt/sources.list.d/tailscale.list
  apt-get update
  apt-get install --yes tailscale
fi
systemctl enable --now tailscaled.service

sudo -H -u aly mkdir -p /home/aly/src
if [[ ! -d /home/aly/src/hoenn ]]; then
  sudo -H -u aly git clone --branch master https://github.com/devon-systems/hoenn.git /home/aly/src/hoenn
fi

activation=$(sudo -H -u aly /nix/var/nix/profiles/default/bin/nix build \
  --accept-flake-config --no-link --print-out-paths \
  '/home/aly/src/hoenn#homeConfigurations.aly@dewford.activationPackage')
sudo -H -u aly env PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin "$activation/activate"

printf '%s\n' \
  'Home Manager is active. Join Tailscale with: sudo tailscale up --hostname=dewford' \
  'Then authenticate agent providers as aly and run: t3 pair'
