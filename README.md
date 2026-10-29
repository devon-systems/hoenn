# hoenn

Nix configuration for personal machines and household services. Hoenn manages
NixOS, nix-darwin, Home Manager, system-manager, and my k3s cluster.

See also [Johto](https://github.com/devon-systems/johto) for the homelab,
[Sinnoh](https://github.com/devon-systems/sinnoh) for production services, and
[Kanto](https://github.com/devon-systems/kanto) for shared inference.

## Architecture

| Host                                                  | Platform       | Flake output                      |
| ----------------------------------------------------- | -------------- | --------------------------------- |
| [`lilycove`](nix/hosts/nixos/lilycove/README.md)      | NixOS          | `nixosConfigurations.lilycove`    |
| [`mauville`](nix/hosts/nixos/mauville/README.md)      | NixOS          | `nixosConfigurations.mauville`    |
| [`pacifidlog`](nix/hosts/nixos/pacifidlog/README.md)  | NixOS          | `nixosConfigurations.pacifidlog`  |
| [`petalburg`](nix/hosts/nixos/petalburg/README.md)    | NixOS          | `nixosConfigurations.petalburg`   |
| [`rustboro`](nix/hosts/nixos/rustboro/README.md)      | NixOS          | `nixosConfigurations.rustboro`    |
| [`sootopolis`](nix/hosts/nixos/sootopolis/README.md)  | NixOS          | `nixosConfigurations.sootopolis`  |
| [`verdanturf`](nix/hosts/darwin/verdanturf/README.md) | nix-darwin     | `darwinConfigurations.verdanturf` |
| `sootopolis`                                          | system-manager | `systemConfigs.sootopolis`        |

Mauville is the k3s server and runs household services and backups. Internal
cluster traffic uses the `hoenn` WireGuard interface. Homebridge uses Mauville's
home LAN for HomeKit discovery. Mauville also collects desktop metrics and logs
for Grafana on Sinnoh's Canalave host.

Comin reconciles host configurations from `master`. Flux reconciles the
Kubernetes resources in `k8s/flux-system/` from the same branch.

The Hoenn WireGuard peer inventory and reusable modules live in
[wg-hoenn](https://github.com/devon-systems/wg-hoenn). This repository keeps its
private keys and host firewall policy. After changing the shared inventory,
update the `wg-hoenn` input in both Hoenn and Sinnoh.

## Repository layout

```text
nix/
├── hosts/<platform>/  Host configuration and hardware state
├── modules/           Shared features and platform defaults
├── devShells.nix      Development tools
└── treefmt.nix        Formatting and linting
k8s/                  Flux and application manifests
secrets/              SOPS-encrypted host secrets
keys/                 Public SOPS recipients
docs/                 Cluster setup and operations
scripts/              Maintenance tools
```

`flake.nix` recursively imports the Nix files under `nix/`. Kubernetes secrets
live in `k8s/secrets/`.

## Development

Enter the pinned development shell with `nix develop`, or run `direnv allow` to
load it automatically. Then run:

```sh
nix fmt
nix flake check
```

Build every output affected by your change. For example:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#darwinConfigurations.verdanturf.config.system.build.toplevel
nix build .#systemConfigs.sootopolis
```

Shared validation and metrics helpers come from the pinned dvnpkgs input.

After Kubernetes changes, run `just check-k8s`. Run `just` to list the other
maintenance commands.

## Deployment

Commit and push validated changes, then let Comin and Flux reconcile `master`.
Run `just flux-status` to inspect the cluster through the `hoenn` context.
Renovate merges routine dependency updates after the required checks pass.

See [cluster operations](docs/kubernetes.md) for bootstrap, backups, Homebridge,
Tailscale access, and update procedures. The
[observability runbook](https://github.com/devon-systems/infra/blob/master/docs/observability.md)
covers metrics and logs. Desktop shortcuts are in the
[Niri keyboard reference](nix/modules/niri/README.md).

## Secrets

Run `just sops-bootstrap` once per machine to derive your local age key from
your SSH key. Then edit secrets with SOPS:

```sh
just sops-edit tailscale.yaml
just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml
```

After changing `keys/`, run `just sops-rekey`. Commit `.sops.yaml` and all
re-encrypted files together. Never commit decrypted secrets or private keys.

This project is available under the [MIT License](LICENSE.md).
