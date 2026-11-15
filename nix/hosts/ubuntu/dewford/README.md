# Dewford

Dewford is a persistent Ubuntu 26.10 development VM on Petalburg. Incus assigns
4 vCPUs, 8 GiB RAM and a 100 GiB disk on Petalburg's existing Btrfs filesystem.
It starts automatically with Petalburg. The private NAT network is
`10.90.0.0/24`; DHCP assigns the guest address. Tailscale gives the guest a
separate identity named `dewford`.

Ubuntu owns the kernel, Docker, Tailscale and the Nix daemon. Standalone Home
Manager owns Aly's user environment and the T3 Code user service. This headless
profile does not import the general Aly profile, which includes Kubernetes
secrets and other machine integrations. Provider credentials are configured
inside the guest and remain on its disk.

## Deploy the host configuration

Run the checks and build Petalburg before committing:

```sh
nix fmt
nix flake check
nix build .#nixosConfigurations.petalburg.config.system.build.toplevel
nix build '.#homeConfigurations.aly@dewford.activationPackage' .#dewford-create
```

Push the validated configuration to `master`. Let Comin reconcile Petalburg.
Check the services without forcing reconciliation:

```sh
ssh petalburg 'systemctl status incus incus-preseed --no-pager'
```

The host configuration creates the network, Btrfs pool and VM profile. It does
not create or replace Dewford. Incus administration uses root's local socket;
the Incus API is not exposed over the network.

## Create and bootstrap Dewford

Run these commands on Petalburg after Comin activates the configuration:

```sh
sudo nix run github:devon-systems/hoenn#dewford-create
sudo incus exec dewford -- cloud-init status --wait
sudo incus exec dewford -- dewford-bootstrap
```

The create command refuses to replace an existing instance. It uses the latest
`images:ubuntu/stonking/cloud` image from the Linux Containers image server.
These are community-built Ubuntu images. Creating a VM does not configure future
Ubuntu release upgrades or replace an existing guest with newer images.

If `incus exec` reports that the guest agent is not ready, retry after the guest
boots. If bootstrap fails, inspect the error and rerun `dewford-bootstrap` after
resolving it. It preserves an existing Hoenn checkout and Nix installation.
Bootstrap requires the Dewford files to be present on Hoenn's `master` branch.

Cloud-init installs the base Ubuntu packages, creates `aly` with the public
`keys/aly_*.pub` SSH keys and passwordless sudo, enables Docker and user lingering,
and configures the guest firewall. The bootstrap script installs a pinned,
checksum-verified multi-user Nix distribution, adds Tailscale's Ubuntu package
repository and activates `homeConfigurations."aly@dewford"` from
`/home/aly/src/hoenn`.

The guest firewall allows SSH and T3's TCP port 3773 through `tailscale0`, plus
Tailscale's UDP transport on port 41641. It does not allow SSH or T3 through the
private Incus interface. Before Tailscale enrollment, use `incus exec` for access.
There are no host directory mounts or Incus sockets inside the guest.

## Enroll and connect

Run Tailscale's interactive enrollment from Petalburg and open the printed login
URL:

```sh
sudo incus exec dewford -- tailscale up --hostname=dewford --ssh
```

Bootstrap enables Tailscale SSH. Tailnet SSH policy controls access to the
guest's local users. After enrollment, connect through the tailnet:

```sh
ssh aly@dewford
systemctl --user status t3code
journalctl --user -u t3code -n 50
```

Authenticate agent providers as `aly`, then run `t3 pair` to pair your T3 client.
The server listens on port 3773 and keeps its state in `/home/aly/.t3`. With
MagicDNS enabled, its address is `http://dewford:3773`; otherwise use the guest's
Tailscale IP. Tailnet access rules must permit the connections.

Home Manager owns `t3code.service`. Use `systemctl --user` to control it. Running
`t3 up` or `t3 service install` can replace that unit and create a second owner.

## Update the user environment

Run as `aly` inside Dewford:

```sh
cd ~/src/hoenn
git pull --ff-only
home-manager switch --flake '.#aly@dewford'
```

Activation can restart T3 when its unit changes. Apply updates while agent jobs
are idle. Install project dependencies inside the guest. Ubuntu package updates
and release upgrades remain separate from Home Manager activation.

## Preserve the guest

The VM disk holds the OS, Nix store, home directory, repositories and credentials.
Stopping or updating the host does not recreate it. Removing the VM destroys
that state.

For a consistent disk snapshot, stop the guest first. Run on Petalburg:

```sh
sudo incus stop dewford
sudo incus snapshot create dewford before-upgrade
sudo incus start dewford
```

Snapshots stay on Petalburg and are not an off-host backup. No automatic backup
or Ubuntu release-upgrade schedule is configured here. Do not start a cloned
worker with Dewford's existing Tailscale identity or copied credentials.
