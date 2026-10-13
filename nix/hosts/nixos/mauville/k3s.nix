_: {
  flake.nixosModules.mauville = {
    config,
    pkgs,
    ...
  }: {
    services.k3s = {
      role = "server";
      clusterInit = true;

      extraFlags = [
        "--node-ip=10.254.1.2"
        "--advertise-address=10.254.1.2"
      ];
    };

    # Tailscale's accepted LAN subnet route otherwise captures proxy UDP traffic.
    systemd.services.k3s-lan-routing = {
      description = "Keep Kubernetes pod traffic to the home LAN local";
      wantedBy = ["multi-user.target"];
      before = ["k3s.service"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip -4 rule add priority 5200 iif cni0 to 192.168.1.0/24 lookup main";
        ExecStop = "${pkgs.iproute2}/bin/ip -4 rule del priority 5200 iif cni0 to 192.168.1.0/24 lookup main";
      };
    };

    services.restic.backups.k3s = {
      paths = [
        "/var/lib/rancher/k3s/server/db/snapshots"
        "/var/lib/rancher/k3s/server/cred"
        "/var/lib/rancher/k3s/server/tls"
      ];
      repository = "rclone:b2:aly-backups/hoenn/mauville/k3s";
      backupPrepareCommand = ''
        ${config.services.k3s.package}/bin/k3s etcd-snapshot save &&
        ${config.services.k3s.package}/bin/k3s etcd-snapshot prune --snapshot-retention 5
      '';
      extraBackupArgs = ["--cleanup-cache"];
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };

    services.restic.backups.k3s-local-path = {
      paths = ["/var/lib/rancher/k3s/storage"];
      repository = "rclone:b2:aly-backups/hoenn/mauville/k3s-local-path";
      extraBackupArgs = ["--cleanup-cache"];
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };

    # Keep volume backups valid before the first local-path PVC is created.
    systemd.tmpfiles.rules = ["d /var/lib/rancher/k3s/storage 0755 root root -"];
  };
}
