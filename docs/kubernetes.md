# Set up and operate the Hoenn cluster

Mauville runs the Hoenn k3s server and workloads. Comin reconciles its NixOS
configuration from `master`, and Flux reconciles applications from
`k8s/flux-system/`.

Internal node traffic uses the Hoenn WireGuard network, including Flannel.
Mauville advertises the Kubernetes API at `10.254.1.2:6443`.

## Validate and deploy the host

Run these checks from the Hoenn development shell:

```sh
nix fmt
nix flake check
nix build .#nixosConfigurations.mauville.config.system.build.toplevel
just check-k8s
```

Commit and push the validated configuration when ready. Comin activates host
changes from `master`. To deploy a reviewed local configuration explicitly, run
`blzrd switch mauville`.

## Bootstrap Flux

### Fetch the kubeconfig

After k3s starts, fetch its kubeconfig:

```sh
just kubeconfig mauville 10.254.1.2
export KUBECONFIG="$HOME/.kube/hoenn"
```

The kubeconfig contains administrator credentials. The recipe writes it with
mode `0600`. Kubeswitch also searches this directory.

### Create the Git deploy key

Create a repository-scoped SSH identity if you do not already have one:

```sh
ssh-keygen -t ed25519 -N '' -C hoenn-flux -f ~/.ssh/hoenn-flux
```

Register `~/.ssh/hoenn-flux.pub` as a deploy key on `devon-systems/hoenn`.
Read access is sufficient because the recipe installs checked-in manifests
without writing to Git.

### Install Flux

Commit and push the configuration, then bootstrap Flux:

```sh
just flux-bootstrap secrets/flux-age.yaml ~/.ssh/hoenn-flux
just flux-status
just reconcile
```

The bootstrap recipe installs the checked-in Flux controller manifests, creates
the `sops-age` and Git credential secrets, and applies the checked-in sync
resources. The SSH identity is stored in the cluster's `flux-system` Git
credential secret. Use a repository-scoped deploy key when available.

`secrets/flux-age.yaml` holds the encrypted Flux age identity, and
`keys/flux_k8s.pub` holds its public recipient. `just sops-rekey` includes that
recipient for Kubernetes secrets while retaining user and host recipients.
Host secrets exclude the Flux recipient.

## Enable the Tailscale operator

Hoenn and Johto join the same tailnet with separate operator identities. Hoenn
uses:

- Hostname `hoenn-operator`
- Operator tag `tag:hoenn-operator`
- Proxy and service tag `tag:hoenn-service`

### Configure the tailnet and credentials

Apply the reviewed tailnet policy in `infra/terraform/tailscale.tf` using the
Infra workflow. It grants the operator ownership of the service tag and
automatically approves services advertised by that tag.

Create a separate OAuth client in the Tailscale admin console with write access
to Devices Core, Auth Keys, and Services. Assign `tag:hoenn-operator` to the
client. Follow the
[operator installation guide](https://tailscale.com/docs/kubernetes-operator/install-operator).

Edit the encrypted credential template:

```sh
just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml
```

Fill in `oauth.clientId` and `oauth.clientSecret` within
`stringData.values.yaml`. Validate, commit, and push the encrypted credentials
before bootstrapping Flux. The operator depends on the secrets reconciliation
and joins the tailnet once its credentials and the tailnet policy are ready.

### Configure ingress and LAN routing

The private-ingress ProxyGroup follows Johto's configuration with one replica
on Mauville. It uses automatic endpoint discovery because Mauville has no
Kubernetes ExternalIP. Give each service a tailnet hostname that is unique
across the clusters. Homebridge uses `homebridge`. Application LAN discovery is
configured separately from cluster transit.

Mauville accepts a Tailscale subnet route for `192.168.1.0/24`, which overlaps
its home LAN. The `k3s-lan-routing` service gives pod traffic arriving on `cni0`
priority to use the main routing table for that subnet. This keeps the ingress
proxy's direct UDP connections on the LAN. The rule applies only to pod traffic
to the home LAN. Internal cluster traffic continues to use Hoenn WireGuard.

## Configure Homebridge

### Complete the initial setup

Homebridge runs on Mauville at
<https://homebridge.narwhal-snapper.ts.net>. Complete the first-run wizard there
to create your administrator account, then install and configure your plugins.
Pair the bridge in Apple Home using the QR code shown in Homebridge.

### Check networking and storage

Homebridge uses host networking and Ciao on Mauville's `wlo1` LAN interface for
HomeKit discovery. The LAN firewall allows TCP `51826` for the main bridge and
`52100` through `52150` for external accessories. Set any child bridge's port
within that range. The web UI is exposed through the Tailscale ingress proxy.

Configuration, pairing state, and plugins persist on `homebridge-data` and are
included in Mauville's local-path volume backups. The init container creates
the initial configuration only when none exists, so UI changes survive
restarts.

### Connect the Nest thermostat

The Nest thermostat uses the `homebridge-nest-accfactory` plugin and its child
bridge. For a migrated Nest account, configure the plugin's Google connection
with the IssueToken request URL and the full Cookie request header from a
Google sign-in. Keep those credentials in the Homebridge UI configuration.
Pair the plugin's child bridge in Apple Home as well as the main bridge.

## Add workloads and nodes

### Add a workload

Put application manifests under `k8s/<app>/` and add their Flux Kustomization to
`k8s/flux-system/kustomization.yaml`. Use dependencies for prerequisites and
`prune: true` and `wait: true` for application reconciliation.

### Add an agent

Import `nixosModules.k3s` and `nixosModules.wireguardHoenn`, then set:

- `services.k3s.role = "agent"`
- `serverAddr` to `https://10.254.1.2:6443`
- `--node-ip` to the host's Hoenn WireGuard address

Add the host key as a SOPS recipient and run `just sops-rekey` before
deployment. Use the same encrypted cluster token as Mauville.

## Back up and restore the cluster

Mauville backs up etcd snapshots and local-path application volumes to B2 with
Restic daily. Each backup retains seven daily, four weekly, and twelve monthly
snapshots. Homebridge's volume includes its configuration, Google credentials,
pairing state, and installed plugins. Treat these backups as secret data.

Database workloads need application-consistent backups in addition to file
backups. The encrypted cluster token must remain available for recovery.
Follow the shared
[k3s recovery guide](https://github.com/devon-systems/infra/blob/master/docs/k3s-control-plane-recovery.md).

## Manage automatic updates

### Review Renovate updates

`renovate.json` uses the same policy as Sinnoh. Renovate tracks Nix inputs,
GitHub Actions, Kubernetes container images, and Flux dependencies. Images and
GitHub Actions use digest pins. OCI Helm charts use chart versions.

Renovate updates the Flux installation as a complete release, including
controller images, API definitions, and permissions. Its Kubernetes manager
skips individual images in `gotk-components.yaml`. The existing required CI
check validates the bundle against its declared release before automatic
merging.

Routine minor, patch, digest, and pin updates can merge automatically after
GitHub's required checks pass. Major updates require manual review. Flake lock
maintenance also merges automatically and is scheduled before 04:00 in the
`America/New_York` timezone. Renovate's
[Dependency Dashboard](https://github.com/devon-systems/hoenn/issues/469) lists
pending updates.

### Check deployment timing

After an update merges to `master`, Comin checks for host changes every ten
minutes on hosts that enable it and activates the new configuration. Flux
checks Git every minute and reconciles the affected Kubernetes resources. Use
`just reconcile` to request an immediate reconciliation.

The scheduled host upgrade jobs also use the committed flake lock. On NixOS,
the daily job runs from 02:00 with up to 45 minutes of delay, sets the next boot
configuration, and does not reboot. Comin handles activation on hosts that
enable it.

### Update dependencies outside Git

Renovate updates dependencies declared in Git. Plugins installed through the
Homebridge UI live on its persistent volume and need updates through the UI.
Image tags that Renovate cannot order need manual tag updates in the manifests.
