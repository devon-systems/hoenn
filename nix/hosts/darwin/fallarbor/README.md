# Fallarbor

Nix-darwin configuration based on Verdanturf. Hardware inventory has not been captured yet.

## Bootstrap

Private bootstrap material is stored locally in `.bootstrap/fallarbor/`. Install the user SSH key as `/Users/aly/.ssh/id_ed25519` with mode `0600`. Syncthing and WireGuard identities are encrypted in `secrets/`.

Before activation, collect macOS's `/etc/ssh/ssh_host_ed25519_key.pub` into `keys/root_fallarbor.pub`, then run `just sops-rekey`. Fallarbor cannot decrypt its system secrets until its real host key has been added. Capture its hardware report on the Mac rather than copying Verdanturf's.
