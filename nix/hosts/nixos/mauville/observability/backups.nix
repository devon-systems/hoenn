_: {
  flake.nixosModules.mauville = {config, ...}: let
    telemetryBackup = {
      name,
      paths,
    }: {
      inherit paths;
      repository = "rclone:b2:aly-backups/hoenn/mauville/${name}";
      extraBackupArgs = ["--cleanup-cache"];
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
      pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };
  in {
    services.restic.backups = {
      loki = telemetryBackup {
        name = "loki";
        paths = ["/var/lib/loki"];
      };
      prometheus = telemetryBackup {
        name = "prometheus";
        paths = ["/var/lib/prometheus2"];
      };
    };
  };
}
