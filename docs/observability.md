# Hoenn desktop telemetry

Mauville runs Prometheus on port `3020` and Loki on port `3030` as NixOS
services, following Johto's Goldenrod setup. Canalave's existing Grafana has
`Hoenn Prometheus` and `Hoenn Loki` data sources. The **Hoenn** folder contains
desktop, drive-health, data-protection, and Comin dashboards. The Grafana
configuration lives in Sinnoh.

## Collection

All seven NixOS hosts and Verdanturf import the shared `observability` module.
Sootopolis's alternative system-manager output also imports it. Deploy one
Sootopolis output at a time.

Alloy collects local node metrics every 60 seconds and pushes them to Mauville.
Metrics include CPU, memory, filesystems, disk I/O, and network traffic.
Linux also enables systemd and power supply collectors. Temperature and
battery metrics depend on the hardware and operating system.
The dashboard leaves gaps when a host sleeps or disconnects and adds no
availability alerts for desktops. Its sample-age panel looks back 24 hours.

Linux hosts also run `smartctl_exporter` on `127.0.0.1:9633`. Alloy scrapes its
cached metrics every minute with `job="smartctl"`. Drive queries run at most
once every five minutes. The exporter discovers SATA and NVMe drives
automatically and checks for standby before polling. USB adapters must
support SMART passthrough.
The system-manager output runs this exporter as root to read controller nodes;
Alloy keeps its existing unprivileged service account.

Grafana's **Hoenn drive health** dashboard shows exporter availability, drive
discovery, SMART status, temperatures, NVMe wear and spare capacity, critical
warnings, media errors, and ATA reallocated, pending, and uncorrectable sectors.
ATA SSD wear indicators retain their vendor-specific normalized values;
they are not a universal percentage of remaining life.
Its SMART exit-status panel helps identify failed drive queries. Unsupported
metrics remain unknown. A successful exporter scrape does not prove that
every drive returned health data. Collection does not schedule drive self-tests.

The **Hoenn data protection** dashboard includes system and user Restic jobs.
Mauville reports its `k3s`, `k3s-local-path`, `sync`, and `roms` backups.
Reporting follows the complete systemd service result, including preparation,
pruning, checks, and cleanup. The previous successful timestamp survives later
failures. Historical backup results remain unknown until a job completes with
reporting enabled. An interrupted job without a completion leaves the previous
completion result unchanged; its success age continues to grow.

Linux hosts read Btrfs device error counters and existing scrub records every
five minutes. The collector starts no scrubs and resets no error counters.
Previous completed scrub results remain available while a new scrub is
incomplete. Successful scrubs may have corrected errors; uncorrectable errors
make the scrub unsuccessful. Resumed scrub completion times use the status
file's modification time because stored duration omits pauses.

The dashboard shows collection health and age alongside scrub results.
Result panels omit Btrfs data when collection fails or is more than 15 minutes
old. Metrics and completed scrub state persist under `/var/lib/hoenn-metrics`.
User backup metrics have separate user-owned directories. Alloy reads these
files through its textfile collector, using the existing node metrics pipeline.

Linux Alloy reads system and user journals, with `host`, `unit`, `user_unit`,
and `level` labels. Journal retention on each machine limits available history.
Verdanturf tails `/var/log/system.log`, `/var/log/nix-darwin-upgrade.log`, and
`/var/log/comin.log`.
It does not collect the macOS unified log or arbitrary application log files.
Alloy keeps journal cursors, file positions, and its metrics write-ahead log
under `/var/lib/alloy`. Metrics can buffer during network outages for up to
24 hours. Log delivery retries are finite, so prolonged outages can lose logs.

NixOS and macOS agents connect through `mauville.hoenn` over Hoenn WireGuard.
Mauville's own agent uses loopback. The system-manager configuration does not
manage networking, so its agent requires an existing Tailscale connection and
uses `mauville.narwhal-snapper.ts.net`. Canalave uses that Tailscale name too.

## Comin deployments

Alloy scrapes Comin's built-in exporter on `127.0.0.1:4243` on each NixOS host
and Verdanturf. Samples carry `job="comin"`, `cluster="hoenn"`, `host`,
`instance`, and `os` labels and use the existing remote-write pipeline.
The system-manager output does not run Comin and does not scrape it.

The **Hoenn Comin** dashboard shows exporter reachability, fetch activity,
failure flags, deployment suspension, Linux reboot requirements, and the
latest reported deployment commit and outcome. Failure flags reset when
Comin restarts. A failed deployment row identifies an attempted deployment,
not the active system revision.

Linux Comin journal entries and Verdanturf's Comin file logs have
`service="comin"`. Select this label in Loki to view deployment logs.
The label applies to newly collected logs; older Linux entries remain
searchable with `unit="comin.service"`.

Johto and Sinnoh use the same local scrape pattern every 30 seconds and
forward metrics to Goldenrod and Canalave respectively. Each region has its
own Comin dashboard in its existing Grafana folder. Johto's Cherrygrove
does not run Comin and is excluded.

## Storage and access

Prometheus keeps metrics under `/var/lib/prometheus2` for 30 days.
Loki stores logs under `/var/lib/loki` with 30-day retention and periodic
compaction. Neither service has a disk-size cap.
Neither data directory has a telemetry backup configured.

The host firewall permits access through the existing trusted `hoenn` and
Tailscale interfaces. These services have no application authentication.
Ports `3020` and `3030` are not opened on the home LAN. Each Alloy HTTP
endpoint listens only on `127.0.0.1:12345`.

## Validate and deploy

Run `nix fmt` and `nix flake check` in Hoenn and Sinnoh.
Build each affected host output before deployment, including Verdanturf's
Darwin output and Sootopolis's system-manager output. Sinnoh's Canalave build
includes the Grafana additions.

Activate Mauville before the clients with `blzrd switch mauville` after
validation. Deploy the remaining hosts through their normal host deployment
workflow, and deploy Canalave to provision the data sources and dashboard.
No Flux changes are required.

On a Linux client, inspect collection with:

```sh
systemctl status alloy
journalctl -u alloy -n 50
```

On Verdanturf, inspect the launch daemon with:

```sh
sudo launchctl print system/org.nixos.alloy
```

From a Hoenn machine, check the server endpoints:

```sh
curl --fail http://mauville.hoenn:3020/-/ready
curl --fail http://mauville.hoenn:3030/ready
```

In Grafana Explore, select **Hoenn Prometheus** and query
`up{job="node"}`. Each awake host reports its `host` and `instance` labels.
Select **Hoenn Loki** and query `{host="petalburg", job="systemd-journal"}`
to inspect a Linux journal, or `{host="verdanturf", job="system-log"}` for
Verdanturf's file logs. Metrics arrive through remote write, so desktops do not
appear as scrape targets in Mauville's Prometheus targets page.
