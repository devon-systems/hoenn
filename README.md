# hoenn

Declarative configuration for my personal machines and household services.
Hoenn combines NixOS, nix-darwin, Home Manager, system-manager, k3s, Flux, and
SOPS to manage hosts, applications, networking, and backups.

For my personal homelab, see [johto](https://github.com/devon-systems/johto).
For my production services, see [sinnoh](https://github.com/devon-systems/sinnoh).

## Architecture

| Host                                             | Cluster role                                    |
| ------------------------------------------------ | ----------------------------------------------- |
| [`mauville`](nix/hosts/nixos/mauville/README.md) | k3s server, household services, and data backup |

Internal cluster traffic uses the `hoenn` WireGuard interface. Homebridge uses
Mauville's home LAN for HomeKit discovery. The Tailscale operator exposes its
web UI on the same tailnet as Johto, with separate Hoenn operator credentials.

Flux watches the `master` branch and reconciles the application, networking,
and secret resources composed by `k8s/flux-system/`. Comin reconciles host
configurations from the same branch on hosts that enable it.

## Configurations

| Host                                                  | Platform       | Flake output                      |
| ----------------------------------------------------- | -------------- | --------------------------------- |
| [`fallarbor`](nix/hosts/nixos/fallarbor/README.md)    | NixOS          | `nixosConfigurations.fallarbor`   |
| [`lilycove`](nix/hosts/nixos/lilycove/README.md)      | NixOS          | `nixosConfigurations.lilycove`    |
| [`mauville`](nix/hosts/nixos/mauville/README.md)      | NixOS          | `nixosConfigurations.mauville`    |
| [`pacifidlog`](nix/hosts/nixos/pacifidlog/README.md)  | NixOS          | `nixosConfigurations.pacifidlog`  |
| [`petalburg`](nix/hosts/nixos/petalburg/README.md)    | NixOS          | `nixosConfigurations.petalburg`   |
| [`rustboro`](nix/hosts/nixos/rustboro/README.md)      | NixOS          | `nixosConfigurations.rustboro`    |
| [`sootopolis`](nix/hosts/nixos/sootopolis/README.md)  | NixOS          | `nixosConfigurations.sootopolis`  |
| [`verdanturf`](nix/hosts/darwin/verdanturf/README.md) | nix-darwin     | `darwinConfigurations.verdanturf` |
| `sootopolis`                                          | system-manager | `systemConfigs.sootopolis`        |

NixOS hardware discovery is captured with nixos-facter, disk layouts are
declared with Disko, and SOPS manages encrypted secrets. Shared WireGuard and
Tailscale modules connect hosts to the networks they need.

## Repository layout

```text
nix/
├── hosts/<platform>/  Per-host configuration and hardware state
├── modules/           Shared feature modules and platform defaults
├── devShells.nix       Development tools
└── treefmt.nix         Formatting and linting configuration
k8s/                   Flux, Kustomize, Helm, and application manifests
secrets/               SOPS-encrypted host secrets
keys/                  Public SOPS recipients
docs/                  Cluster setup and operations
scripts/               Repository maintenance utilities
.github/workflows/     Flake checks and configuration builds
```

`flake.nix` recursively imports the modules under `nix/`. Each Nix file there
declares or extends a flake output, so new modules do not need to be added to a
central import list.

Kubernetes applications are grouped by service under `k8s/`.
`k8s/flux-system/` defines their reconciliation order. Kubernetes secrets live
in `k8s/secrets/`.

## Work locally

Enter the pinned development shell with `nix develop`, or use `direnv allow`
to load it automatically. From the repository root:

```sh
nix fmt
nix flake check
```

Run `just` to list maintenance commands.

The Kubernetes recipes match Sinnoh and Johto. Use `just check-k8s` for manifest
validation, `just reconcile` to reconcile the Flux root, `just reconcile <name>`
for a workload, and `just flux-status` to inspect reconciliation. These Flux
commands explicitly target the `hoenn` context.
`just kubeconfig <host> <api-address>` fetches a named administrator kubeconfig.
`just flux-bootstrap <age-key-file> <git-ssh-key-file>` installs SOPS decryption
and bootstraps the checked-in Flux version.

See [Hoenn cluster setup](docs/kubernetes.md) for bootstrap, Homebridge, backups,
and Tailscale service exposure.

## Deployment

`blzrd` deploys `mauville` and `petalburg`. For example:

```sh
blzrd switch mauville
```

`switch` activates the configuration and sets the boot default. `boot` sets
the boot default without activating it. Without a host name, `blzrd switch`
deploys every registered node.

Comin deploys host changes from `master` on hosts that enable it. Flux deploys
Kubernetes workloads from `master`. Renovate uses Sinnoh's dependency update
policy and automatically merges routine updates after required checks pass.
See [automatic updates](docs/kubernetes.md#automatic-updates) for the deployment
flow and the limits of Git-managed updates.

## Secrets

SOPS encrypts secrets for the recipients in `.sops.yaml`. Public keys live in
`keys/`. To edit a host secret from the development shell:

```sh
just sops-edit tailscale.yaml
```

For Kubernetes secrets, pass the full path, such as
`just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml`.
Use `just sops-bootstrap` once to derive your local age key from your SSH key.

See the [Niri keyboard reference](nix/modules/niri/README.md) for the
configured desktop shortcuts.

This project is available under the [MIT License](LICENSE.md).
