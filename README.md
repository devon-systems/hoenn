# hoenn

Declarative configuration for my personal machines. Hoenn uses a flake-parts
Nix flake to compose NixOS, nix-darwin, Home Manager, and system-manager configurations,
with shared modules for packages, desktop environments, networking, secrets,
and automatic upgrades.

For my personal homelab, see [johto](https://github.com/alyraffauf/johto). For
my production services, see [sinnoh](https://github.com/alyraffauf/sinnoh).

## Configurations

| Host                                                 | Platform       | Flake output                     |
| ---------------------------------------------------- | -------------- | -------------------------------- |
| [`fallarbor`](nix/hosts/nixos/fallarbor/README.md)   | NixOS          | `nixosConfigurations.fallarbor`  |
| [`mauville`](nix/hosts/nixos/mauville/README.md)     | NixOS          | `nixosConfigurations.mauville`   |
| [`pacifidlog`](nix/hosts/nixos/pacifidlog/README.md) | NixOS          | `nixosConfigurations.pacifidlog` |
| [`petalburg`](nix/hosts/nixos/petalburg/README.md)   | NixOS          | `nixosConfigurations.petalburg`  |
| [`verdanturf`](nix/hosts/nixos/verdanturf/README.md) | NixOS (Asahi)  | `nixosConfigurations.verdanturf` |
| [`rustboro`](nix/hosts/nixos/rustboro/README.md)     | NixOS          | `nixosConfigurations.rustboro`   |
| [`sootopolis`](nix/hosts/nixos/sootopolis/README.md) | NixOS          | `nixosConfigurations.sootopolis` |
| [`fortree`](nix/hosts/darwin/fortree/README.md)      | nix-darwin     | `darwinConfigurations.fortree`   |
| `sootopolis`                                         | system-manager | `systemConfigs.sootopolis`       |

NixOS hardware discovery is captured with nixos-facter, disk layouts are
declared with Disko, and SOPS manages encrypted secrets. Shared WireGuard and
Tailscale modules connect hosts to the networks they need.

## Repository layout

```text
nix/
├── hosts/  Per-host composition and hardware state
├── modules/  feature modules for NixOS, nix-darwin, Home Manager, and system-manager
├── devShells.nix  Development tools
└── treefmt.nix  Formatting and linting configuration
keys/  Public SSH keys used as age recipients
secrets/  SOPS-encrypted configuration
scripts/  Repository maintenance utilities
.github/workflows/  Flake checks and configuration builds
```

`flake.nix` recursively imports the modules under `nix/`. Each Nix file there
declares or extends a flake output, so new modules do not need to be added to a
central import list.

## Work locally

Enter the pinned development shell with `nix develop`, or use `direnv allow`
to load it automatically. From the repository root:

```sh
nix fmt
nix flake check
```

Run `just` to list maintenance commands.

## Deployment

`blzrd` deploys `mauville` and `petalburg`. For example:

```sh
blzrd switch mauville
```

`switch` activates the configuration and sets the boot default. `boot` sets
the boot default without activating it. Without a host name, `blzrd switch`
deploys every registered node.

## Secrets

SOPS encrypts secrets for the recipients in `.sops.yaml`. Public keys live in
`keys/`. To edit a host secret from the development shell:

```sh
just sops-edit tailscale.yaml
```

See the [Niri keyboard reference](nix/modules/niri/README.md) for the
configured desktop shortcuts.

This project is available under the [MIT License](LICENSE.md).
