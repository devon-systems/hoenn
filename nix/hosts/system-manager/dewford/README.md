# Dewford

Ubuntu 26.10 development VM on [Petalburg](../../nixos/petalburg/README.md), managed
with system-manager, Determinate Nix and Home Manager's shared `aly` profile.
T3 Code manages its own background service, configured manually.

| Component    | Configuration                                       |
| ------------ | --------------------------------------------------- |
| CPU          | 4 vCPUs                                             |
| Memory       | 8 GiB                                               |
| Storage      | 100 GiB on Btrfs                                    |
| Access       | Tailscale SSH as `aly`; T3 at `http://dewford:3773` |
| Flake output | `systemConfigs.dewford`                             |

See the [development VM runbook](../../../../docs/development-vms.md) for setup
and operations.
