_: {
  flake.nixosModules.mauville = {config, ...}: {
    services.k3s = {
      role = "server";
      clusterInit = true;

      extraFlags = [
        "--node-ip=10.254.1.2"
        "--advertise-address=10.254.1.2"
      ];
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

    networking.firewall.allowedUDPPortRanges = [
      {
        from = 31667;
        to = 31680;
      }
    ];
  };
}
