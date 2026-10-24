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

Comin reconciles host configurations from `master`. Flux reconciles Kubernetes
resources from `master`. Commit and push validated changes, then let the existing
automation reconcile them. Use read-only checks to verify rollout.

Manual deployment, forced reconciliation, Nix store copies to hosts, and restarts
of deployment services require an explicit user request. Never deploy to test a
configuration.

Use `just flux-bootstrap` for user-requested initial installation. Apply repository
manifests with `kubectl` only during user-requested bootstrap or cluster recovery.
`just flux-status` targets the `hoenn` context explicitly.

`renovate.json` follows Sinnoh's update policy. Keep shared dependency rules
generic.

## Keep secrets out of Git

Do not commit decrypted secrets or private keys. Use `just sops-edit <file>.yaml` to edit a secret. When `keys/` changes, run `just sops-rekey`, review `.sops.yaml` and every encrypted file, then commit them together.

Use `just sops-bootstrap` once to derive your local age key from your SSH key.
For host secrets, use `just sops-edit tailscale.yaml`. For Kubernetes secrets,
pass the full path, such as
`just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml`.
