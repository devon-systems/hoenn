# Flake & Project

Load this file only for flake setup, direnv, or permanent installs. Agent `nix develop` and `nix shell` calls still need `-c`; see the `-c` rule in `SKILL.md`.

```bash
# Interactive (no -c — for users, not agents)
nix develop
nix shell nixpkgs#pkg1 nixpkgs#pkg2

# Flake lifecycle
nix flake init -t nixpkgs#python
nix flake update && nix flake check
nix build && nix run .#app

# direnv (auto-activate on cd)
echo "use flake" > .envrc && direnv allow
echo "use nix" > .envrc && direnv allow

# Permanent (rare)
nix profile install nixpkgs#pkg
```
