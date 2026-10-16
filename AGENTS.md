# Work in Hoenn

Hoenn configures personal machines. It contains NixOS, nix-darwin, Home Manager, and system-manager configurations. Keep host-specific state in `nix/hosts/<platform>/<host>/`. Put shared feature modules in `nix/modules/<feature>/`. Platform defaults live in `nix/modules/nixos/`, `nix/modules/darwin/`, and `nix/modules/system-manager/`. Cross-platform defaults live in `nix/modules/default/`.

`flake.nix` imports the Nix files under `nix/`. `scripts/` holds maintenance tools. Keep host secrets in `secrets/`, Kubernetes secrets in `k8s/secrets/`, and public SOPS recipients in `keys/`.

Mauville runs the Hoenn k3s server. Internal cluster transit uses Hoenn
WireGuard. `k8s/` contains Flux-managed household services. Follow
`docs/kubernetes.md` for bootstrap, operations, and automatic updates.

## Check a change

Run `nix fmt` and `nix flake check` before you commit. Build each output affected by the change.

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#darwinConfigurations.verdanturf.config.system.build.toplevel
nix build .#systemConfigs.sootopolis
```

If a host's `facter.json` or `system-profiler.json` changes, run
`nix run github:alyraffauf/infra#generate-host-readmes`. Capture Darwin hardware
over SSH with `nix run github:alyraffauf/infra#generate-host-readmes -- --capture-darwin <host>`.
Do not edit text between generated-section markers in a host README.

After changing compositor keybindings, regenerate the keyboard references:

```sh
bun scripts/generate-niri-keybindings.ts
bun scripts/generate-sway-keybindings.ts
```

Run both commands with `--check` to verify the committed references. Edit the
compositor configs, not the generated Markdown files.

When you change a Kubernetes resource, update its `kustomization.yaml` or Flux
resource in the same change. Do not reformat
`k8s/flux-system/gotk-components.yaml`.

Run `just check-k8s` after Kubernetes changes. It renders Flux targets and local
Helm releases with their configured values. The check needs network access to
fetch schemas. It excludes encrypted SOPS documents and generated CRD
definitions. Other resources fail if their schema is missing. It validates
remote Helm release declarations but does not render their charts.

## Commit messages

Use scoped Conventional Commits: `fix(<scope>): <description>` for fixes and `feat(<scope>): <description>` for new features. Choose a program, module, or path as the scope. For example, `fix(niri): correct workspace keybinding` or `feat(nix/modules/desktop): add screen sharing support`.

## Deploy deliberately

`mauville` and `petalburg` are the registered `blzrd` nodes, declared in their `nix/hosts/nixos/<host>/default.nix` files. Run `blzrd switch <host>` to activate one, or `blzrd boot <host>` to set its next boot. Do not use a bare `blzrd switch` unless you mean to target every registered node. Never deploy only to test a configuration.

Flux deploys Kubernetes changes from `master`. Use `just flux-bootstrap` for
initial installation. Do not apply repository manifests with `kubectl` during
normal operation. Use `kubectl` to apply manifests only during bootstrap or
cluster recovery. `just reconcile` and `just flux-status` target the `hoenn`
context explicitly.

`renovate.json` follows Sinnoh's update policy. Keep shared dependency rules
generic. Host reconciliation uses Comin where enabled, and Flux reconciles
Kubernetes workloads.

## Keep secrets out of Git

Do not commit decrypted secrets or private keys. Use `just sops-edit <file>.yaml` to edit a secret. When `keys/` changes, run `just sops-rekey`, review `.sops.yaml` and every encrypted file, then commit them together.

Use `just sops-bootstrap` once to derive your local age key from your SSH key.
For host secrets, use `just sops-edit tailscale.yaml`. For Kubernetes secrets,
pass the full path, such as
`just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml`.
