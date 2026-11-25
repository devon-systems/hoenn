#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID != 0 ]]; then
  echo 'Run as root inside Oldale.' >&2
  exit 1
fi

nix=/nix/var/nix/profiles/default/bin/nix
if [[ ! -x $nix ]] || ! "$nix" --version | grep -q 'Determinate'; then
  installer=$(mktemp)
  trap 'rm "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 --fail --show-error --location \
    https://install.determinate.systems/nix --output "$installer"
  sh "$installer" install --no-confirm
fi

if ! "$nix" --version | grep -q 'Determinate'; then
  echo 'Migrate this installation to Determinate Nix before activating Oldale.' >&2
  exit 1
fi

sudo -H -u aly mkdir -p /home/aly/src
if [[ ! -d /home/aly/src/hoenn ]]; then
  sudo -H -u aly git clone --branch master https://github.com/devon-systems/hoenn.git /home/aly/src/hoenn
fi

"$nix" run --accept-flake-config --inputs-from /home/aly/src/hoenn system-manager -- \
  switch --flake '/home/aly/src/hoenn#systemConfigs.oldale'

/usr/bin/systemctl is-active --quiet system-manager.target home-manager-aly.service \
  determinate-settings.service oldale-setup.service oldale-shell.service

printf '%s\n' \
  'System Manager and Home Manager are active.' \
  'Connect over Tailscale with: ssh aly@oldale' \
  'Set up T3 Code manually as aly with: t3 up --lan --no-connect'
