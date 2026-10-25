# Work in Hoenn

Hoenn configures personal machines with NixOS, nix-darwin, Home Manager, and system-manager.

- Hosts: `nix/hosts/<platform>/<host>/`
- Shared features: `nix/modules/<feature>/`
- Platform defaults: `nix/modules/{nixos,darwin,system-manager}/`
- Cross-platform defaults: `nix/modules/default/`
- Maintenance tools: `scripts/`; host secrets: `secrets/`; Kubernetes secrets: `k8s/secrets/`; public SOPS recipients: `keys/`

`flake.nix` imports Nix files under `nix/`. Mauville runs the k3s server; internal cluster transit uses Hoenn WireGuard. Flux manages household services in `k8s/`. See `docs/kubernetes.md` for bootstrap, operations, and updates.

## Validate changes

Before committing, run `nix fmt` and `nix flake check`. Build every affected output:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#darwinConfigurations.verdanturf.config.system.build.toplevel
nix build .#systemConfigs.sootopolis
```

After `facter.json` or `system-profiler.json` changes, run `nix run github:devon-systems/infra#generate-host-readmes`. Capture Darwin hardware with `nix run github:devon-systems/infra#generate-host-readmes -- --capture-darwin <host>`. Never edit text between generated-section markers.

After compositor keybinding changes, edit the compositor config and regenerate both references:

```sh
bun scripts/generate-niri-keybindings.ts
bun scripts/generate-sway-keybindings.ts
```

Use `--check` on both commands to verify committed references; never edit generated Markdown.

For Kubernetes changes, update resource lists and Flux resources together. Never reformat `k8s/flux-system/gotk-components.yaml`. Run `just check-k8s`; it renders Flux targets and local Helm releases with configured values, fetches schemas over the network, skips encrypted SOPS documents and generated CRDs, fails on other missing schemas, and validates remote Helm declarations without rendering their charts.

## Commit messages

Use scoped Conventional Commits with a program, module, or path as scope, such as `fix(niri): correct workspace keybinding`.

## Deploy deliberately

Comin reconciles hosts and Flux reconciles Kubernetes from `master`. Push validated changes, let automation reconcile, and verify with read-only checks.

Manual deployment, forced reconciliation, Nix store copies to hosts, and deployment-service restarts require an explicit user request. Never deploy to test. Use `just flux-bootstrap` only for requested initial installation; apply manifests with `kubectl` only for requested bootstrap or recovery. `just flux-status` uses the `hoenn` context.

`renovate.json` follows Sinnoh's policy; keep shared dependency rules generic.

## Keep secrets out of Git

Never commit decrypted secrets or private keys. Run `just sops-bootstrap` once to derive the local age key from SSH. Edit host secrets with `just sops-edit tailscale.yaml` and Kubernetes secrets with their full path, such as `just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml`.

After `keys/` changes, run `just sops-rekey`; review and commit `.sops.yaml` with every re-encrypted file.
