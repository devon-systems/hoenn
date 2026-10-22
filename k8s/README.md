# Kubernetes resources

`flux-system/` contains bootstrap manifests and one Flux Kustomization per
component. `namespaces/` owns namespace declarations, `secrets/` owns encrypted
secrets, and each remaining directory owns a service and its configuration.
Nix owns K3s, host networking, and backups.

Namespaces reconcile before secrets and namespace consumers. Dependencies
represent prerequisites, not a global application readiness barrier. Keep
resource identities and Flux owners stable when reorganizing files. To transfer
ownership, disable pruning on the old owner, reconcile and verify, transfer the
resource, verify both inventories, then restore pruning.

Run `just check-k8s` or `nix run .#check-k8s` from the repository root. The check
prints the dependency graph and resource owners, renders local Helm charts,
and validates schemas against the pinned K3s minor. Encrypted documents and
upstream chart contents are not validated; upstream release declarations are.

Homebridge requires Mauville's home LAN for HomeKit discovery. Its private
route stays with the service because it is this cluster's only application.

Application pod templates disable API tokens and service links, use
`RuntimeDefault` seccomp, prevent privilege escalation, and drop `NET_RAW` or
`ALL`. Keep stronger existing settings. Exceptions use pod-template annotations
under `security.aly.codes/exception-` with a reason for each affected setting.
The rules are `api-token`, `service-links`, `seccomp`, `privilege-escalation`,
`net-raw`, `host-network`, `host-pid`, `host-ipc`, `host-port`, `privileged`,
`host-path`, and `added-capabilities`. Unknown, empty, or unused exceptions fail
the check. Generated Flux workloads and unrendered upstream charts are excluded.
