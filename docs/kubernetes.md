# Set up the Hoenn cluster

Mauville runs the Hoenn k3s server and workloads. Comin reconciles its NixOS
configuration from `master`. Flux reconciles applications from `k8s/flux-system/`.
Internal node traffic uses the Hoenn WireGuard network, including Flannel.
Mauville advertises the Kubernetes API at `10.254.1.2:6443`.

## Validate and deploy the host

From the Hoenn development shell:

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

After k3s starts, fetch its kubeconfig:

```sh
just kubeconfig mauville 10.254.1.2
export KUBECONFIG="$HOME/.kube/hoenn"
```

The kubeconfig contains administrator credentials. The recipe writes it with
mode `0600`. Kubeswitch also searches this directory.

Create a repository-scoped SSH identity if you do not already have one:

```sh
ssh-keygen -t ed25519 -N '' -C hoenn-flux -f ~/.ssh/hoenn-flux
```

Register `~/.ssh/hoenn-flux.pub` as a deploy key with write access on
`devon-systems/hoenn`. Then bootstrap Flux:

```sh
just flux-bootstrap secrets/flux-age.yaml ~/.ssh/hoenn-flux
just flux-status
just reconcile
```

The bootstrap recipe installs the checked-in Flux controller manifests, creates
the `sops-age` and Git credential secrets, and applies the checked-in sync
resources. Commit and push the configuration before running it. The SSH
identity is stored in the cluster's `flux-system` Git credential secret. Use
a repository-scoped deploy key when available.

`secrets/flux-age.yaml` holds the encrypted Flux age identity.
`keys/flux_k8s.pub` holds its public recipient. `just sops-rekey` includes that
recipient for Kubernetes secrets while retaining user and host recipients.
Host secrets exclude the Flux recipient.

## Enable the Tailscale operator

Hoenn and Johto join the same tailnet with separate operator identities.
Hoenn uses the hostname `hoenn-operator`, the operator tag
`tag:hoenn-operator`, and the proxy and service tag `tag:hoenn-service`.

Apply the reviewed tailnet policy in `infra/terraform/tailscale.tf` using the
Infra workflow. It grants the operator ownership of the service tag and
automatically approves services advertised by that tag.

Create a separate OAuth client in the Tailscale admin console with write access
to Devices Core, Auth Keys, and Services. Assign `tag:hoenn-operator` to the
client. Follow the [operator installation guide](https://tailscale.com/docs/kubernetes-operator/install-operator).

Edit the encrypted credential template:

```sh
just sops-edit k8s/secrets/tailscale-operator-values.sops.yaml
```

Fill in `oauth.clientId` and `oauth.clientSecret` within `stringData.values.yaml`.
Validate, commit, and push the encrypted credentials before bootstrapping Flux.
The operator depends on the secrets reconciliation and joins the tailnet once
its credentials and the tailnet policy are ready.

The private-ingress ProxyGroup follows Johto's configuration with one replica
on Mauville. It uses automatic endpoint discovery because Mauville has no
Kubernetes ExternalIP. Give Hoenn services distinct tailnet hostnames, such as
`hoenn-homebridge`, so they do not advertise Johto's service names.
Application LAN discovery is configured separately from cluster transit.

## Add workloads and nodes

Put application manifests under `k8s/<app>/` and add their Flux Kustomization to
`k8s/flux-system/kustomization.yaml`. Use dependencies for prerequisites and
`prune: true` and `wait: true` for application reconciliation.

For a new agent, import `nixosModules.k3s` and `nixosModules.wireguardHoenn`, set
`services.k3s.role = "agent"`, point `serverAddr` to
`https://10.254.1.2:6443`, and set `--node-ip` to that host's Hoenn WireGuard
address. Add its host key as a SOPS recipient and run `just sops-rekey` before
deployment. Use the same encrypted cluster token as Mauville.

Mauville backs up etcd snapshots and local-path application volumes to B2 with
Restic. Database workloads need application-consistent backups in addition to
file backups. The encrypted cluster token must remain available for recovery.
Follow the shared [k3s recovery guide](../../infra/docs/k3s-control-plane-recovery.md).
