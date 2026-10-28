_: {
  flake.nixosModules.mauville = {config, ...}: {
    services.k3s = {
      role = "server";
      clusterInit = true;
      disable = ["traefik" "servicelb"];

      extraFlags = [
        "--node-ip=10.254.1.2"
        "--advertise-address=10.254.1.2"
        "--kube-controller-manager-arg=terminated-pod-gc-threshold=10"
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

    # Keep volume backups valid before the first local-path PVC is created.
    systemd.tmpfiles.rules = ["d /var/lib/rancher/k3s/storage 0755 root root -"];
  };
}
