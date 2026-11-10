# Remote builders

Connect as `aly` through Tailscale SSH to build on either desktop. Tailscale SSH is enabled on both desktops.

| Builder   | Platform         | Jobs per client |
| --------- | ---------------- | --------------- |
| Lavaridge | `x86_64-linux`   | 4               |
| Fallarbor | `aarch64-darwin` | 2               |

Hoenn configures Rustboro, Sootopolis, and Lilycove to use both builders, and Lavaridge to use Fallarbor. Configure Verdanturf and Fallarbor manually as described below. Local builds remain enabled. Job limits apply separately to each client.

`nix/modules/remote-builds/default.nix` owns the builder declarations. These are native builds on a remote machine, so request an output for the builder's platform.

## Determinate Nix Macs

The Macs' Nix configuration stays unmanaged. Keep `nix.enable = false`. Edit `/etc/nix/nix.custom.conf` manually, preserving its existing cache and trust settings.

On Verdanturf, add or update these settings:

```ini
builders = ssh-ng://aly@lavaridge.narwhal-snapper.ts.net x86_64-linux - 4 2 benchmark,big-parallel,kvm,nixos-test - ; ssh-ng://aly@fallarbor.narwhal-snapper.ts.net aarch64-darwin - 2 1 benchmark,big-parallel -
builders-use-substitutes = true
```

On Fallarbor, use only Lavaridge:

```ini
builders = ssh-ng://aly@lavaridge.narwhal-snapper.ts.net x86_64-linux - 4 2 benchmark,big-parallel,kvm,nixos-test -
builders-use-substitutes = true
```

Keep Fallarbor's existing `extra-trusted-users = aly` setting for trusted remote builds. Do not replace either Mac's configuration file or transfer its ownership to nix-darwin.

## Verify access

Nix connects from the local daemon as root. Check access from that account, even if SSH already works as your user:

```sh
sudo ssh aly@lavaridge.narwhal-snapper.ts.net true
sudo ssh aly@fallarbor.narwhal-snapper.ts.net true
sudo nix store info --store ssh-ng://aly@lavaridge.narwhal-snapper.ts.net
sudo nix store info --store ssh-ng://aly@fallarbor.narwhal-snapper.ts.net
```

Verify and accept the SSH host keys on the initial connection. Tailscale SSH policy must allow unattended access as `aly`; an interactive approval requirement can block builds.

Inspect the settings read by a fresh root CLI. This does not query the running daemon:

```sh
sudo nix config show | rg '^(builders|builders-use-substitutes) ='
```

On NixOS, also inspect `/etc/nix/machines` for the actual builder list.

Build the desired flake output normally. To require remote execution for an uncached output, add `--max-jobs 0 -L`. The build log should name the remote builder. Already cached outputs do not exercise remote execution.

If a Mac keeps using old settings, check whether its Nix daemon has reloaded the configuration. Any manual restart is a separate, deliberate operation.

## References

- [Nix distributed builds](https://nix.dev/tutorials/nixos/distributed-builds-setup.html)
- [Determinate Nix with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
