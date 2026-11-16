# Operate development VMs

Use this runbook for Incus guests managed with system-manager and Home Manager.
Replace `<guest>`, `<hypervisor>` and `<user>` with the names from the guest's
README. For [Dewford](../nix/hosts/system-manager/dewford/README.md), these are
`dewford`, `petalburg` and `aly`.

The examples use the `<guest>-create` and `<guest>-enroll` packages and the
`<guest>-bootstrap` command provided by each guest's provisioning configuration. These commands must exist
before you can create that guest.

## Register a guest

Keep the guest's configuration under `nix/hosts/system-manager/<guest>/`:

- Assemble `systemConfigs.<guest>` in `default.nix`, using named system modules.
- Import Home Manager's NixOS module into the system-manager configuration and
  attach the shared user profile and guest-specific modules through
  `home-manager.users.<user>`. Keep one
  system output for activation of both system and user settings.
- Define the Incus resource profile in the guest's `incus.nix`. Import that
  NixOS module in the hypervisor's configuration.
- Keep cloud-init data, the bootstrap script and the creation package alongside
  the guest. Select the image and native packages there.
- Record resources and configuration ownership in the host README. Link to this
  runbook for operating procedures.

Configure shared Incus networking and storage on the hypervisor. Leave the
native distribution's accounts and passwords intact when adding an existing
machine to system-manager. Leave Nix's generated configuration and daemon units
under the Determinate installer's ownership; manage custom settings through
`/etc/nix/nix.custom.conf`.

## Deploy the hypervisor configuration

Run from the Hoenn checkout before committing:

```sh
nix fmt
nix flake check
nix build '.#nixosConfigurations.<hypervisor>.config.system.build.toplevel'
nix build '.#systemConfigs.<guest>' '.#<guest>-create'
```

Push the validated configuration to `master`. Let Comin reconcile the
hypervisor, then check its services:

```sh
ssh <hypervisor> 'systemctl status incus incus-preseed --no-pager'
```

Deploying the hypervisor creates the configured network, storage pool and
resource profiles. Create each guest separately with its provisioning command.

## Create a guest

Run on the hypervisor after the configuration activates:

```sh
sudo nix run 'github:devon-systems/hoenn#<guest>-create'
```

The creation command waits for the guest agent and cloud-init, then enrolls the
guest in Tailscale using the hypervisor's configured auth key. The key is read
from the hypervisor's runtime secret file and forwarded over Incus stdin. It is
not embedded in cloud-init, stored in the Nix store or written to the guest disk.
Each guest keeps its own Tailscale identity.

If cloud-init fails, inspect `/var/log/cloud-init-output.log` inside the guest
before running the bootstrap command.

The creation command refuses to replace an existing instance. Select a new image
in the guest configuration when needed; creating an instance does not configure
future distribution upgrades or update an existing guest to a newer image.

Cloud-init installs native packages, creates the development account and
configures initial access. The bootstrap runs the official Determinate installer
when needed, then uses the pinned system-manager input to activate
`systemConfigs.<guest>`. System Manager starts the native services and activates
Home Manager for the development user.

Publish the guest configuration before bootstrapping; the script uses the Hoenn
checkout inside the guest. To recover from failure, inspect the error, resolve
it and rerun the installed bootstrap command.

Use `incus exec` for access before Tailscale enrollment. Check the guest's
cloud-init data for its image, package repositories, account and firewall rules.

## Enroll the user key for secrets

Before bootstrapping a guest that imports `homeModules.aly`, register its user
SSH key for SOPS. The shared profile decrypts secrets with
`~/.ssh/id_ed25519`. If that file does not exist, generate the key inside the
guest without a passphrase. Copy only its public key to
`keys/aly_<guest>.pub` in Hoenn, run `just sops-rekey`, and review and publish
the resulting key and encrypted-file changes together.

For an existing guest, update its Hoenn checkout before activation so it
contains the new recipients. Follow this step for existing guests as well as fresh instances.
Never copy a private key into the repository.

## Bootstrap system and user configuration

After publishing the user key and re-encrypted secrets, run on the hypervisor:

```sh
sudo incus exec <guest> -- <guest>-bootstrap
```

## Migrate an existing guest

Apply changes while agent jobs are idle. Take a disk snapshot first, as described
below. Copy the current guest bootstrap script into the running guest rather
than using an older copy installed by its original cloud-init configuration.
For example, from the Hoenn checkout:

```sh
cat nix/hosts/system-manager/<guest>/bootstrap.sh | \
  ssh <user>@<guest> 'sudo tee /usr/local/sbin/<guest>-bootstrap >/dev/null'
```

Update the guest's Hoenn checkout with `git pull --ff-only`, then run its
bootstrap command as root. It invokes the Determinate installer if an upstream
Nix installation is detected. Follow the
[official migration guide](https://docs.determinate.systems/guides/migrating-from-upstream-nix/)
if the installer reports an existing receipt or cannot migrate the installation.
Do not uninstall Nix or remove its store as a routine bootstrap step.

Existing guests also need any native packages newly added to cloud-init before
the system-manager activation. For Dewford, verify that Docker, OpenSSH,
Tailscale and unattended-upgrades are installed. Reapplying cloud-init is not
part of migration.

## Connect over Tailscale

Creation enrolls the guest automatically. To enroll an existing guest or retry
enrollment after a provisioning failure, run on the hypervisor:

```sh
sudo nix run 'github:devon-systems/hoenn#<guest>-enroll'
```

Already-enrolled guests are left connected. Tailnet SSH policy must permit
access to the chosen local user. Connect from another tailnet machine:

```sh
ssh <user>@<guest>
```

Use the guest's own Tailscale IP or MagicDNS name. Private Incus addresses are
local to the hypervisor's network unless routing is configured separately.

## Set up T3 Code manually

Home Manager installs the T3 CLI through the shared user profile. After system
activation, run as the development user to let T3 install its own service:

```sh
t3 up --lan --no-connect
t3 service status
systemctl --user status t3code
```

Authenticate agent providers as the development user, then run `t3 pair` to pair
a client. Configure access through T3's commands; Dewford uses
`http://dewford:3773`. The guest firewall and tailnet policy must allow access.

T3 owns its service and runtime updates. Use `t3 service` and `t3 update` to
manage them; do not also define `t3code.service` in Home Manager. When migrating
from a Nix-managed T3 unit, finish system activation before this manual setup.

## Set a local password

If cloud-init created a locked account, use sudo to set its password without
being asked for the current password:

```sh
sudo passwd <user>
```

Tailscale SSH continues to use tailnet authentication. System-manager activation
preserves the native account's password.

## Update system and user configuration

Run inside the guest's Hoenn checkout while agent jobs are idle:

```sh
git pull --ff-only
sudo /run/system-manager/sw/bin/system-manager switch --flake '.#systemConfigs.<guest>'
```

This activates both system configuration and Home Manager. Changes can restart
managed services. T3's service is managed separately by T3. There is no separate
standalone Home Manager output to switch.

Manage native packages and distribution release upgrades separately. Dewford
runs unattended Ubuntu security upgrades without automatic reboots. It has no
automatic system-manager activation timer, so Nix configuration updates do not
interrupt agent jobs on a schedule.

## Snapshot and back up a guest

For a consistent disk snapshot, stop the guest first. Run on the hypervisor:

```sh
sudo incus stop <guest>
sudo incus snapshot create <guest> before-upgrade
sudo incus start <guest>
```

Snapshots stay on the hypervisor. Set up an off-host backup separately for data
that must survive loss of that machine. Check the guest README for any configured
backup policy.

Stopping or updating the hypervisor preserves guest disks. Deleting an instance
destroys its state. Before starting a cloned worker, give it a separate Tailscale
identity and configure its credentials independently.
