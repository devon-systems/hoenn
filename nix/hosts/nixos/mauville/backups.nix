_: {
  flake.nixosModules.mauville = {
    config,
    pkgs,
    self,
    ...
  }: let
    resticPasswordFile = config.sops.secrets.restic-password.path;
    rcloneConfigFile = config.sops.secrets.rclone-b2.path;
  in {
    users.users.aly.linger = true;

    systemd.tmpfiles.rules = [
      "d /var/lib/hoenn-metrics/backups-user-aly 0755 aly ${config.users.users.aly.group} -"
    ];

    sops.secrets = {
      restic-password = {
        sopsFile = self + "/secrets/restic.yaml";
        key = "PASSWORD";
        owner = "aly";
        mode = "0400";
      };
      rclone-b2 = {
        sopsFile = self + "/secrets/b2.yaml";
        key = "rclone_config";
        owner = "aly";
        mode = "0400";
      };
    };

    home-manager.users.aly = {
      config,
      lib,
      ...
    }: let
      folderPath = name: let
        path = config.hoenn.syncthing.folders.${name}.path;
      in
        if lib.hasPrefix "~/" path
        then "${config.home.homeDirectory}/${lib.removePrefix "~/" path}"
        else path;

      backup = name: path: schedule: {
        paths = [path];
        repository = "rclone:b2:aly-backups/hoenn/mauville/${name}";
        passwordFile = resticPasswordFile;
        rcloneOptions.config = rcloneConfigFile;
        extraOptions = ["rclone.program=${pkgs.rclone}/bin/rclone"];
        initialize = true;
        extraBackupArgs = ["--cleanup-cache"];
        pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 3"];
        runCheck = true;
        timerConfig = {
          OnCalendar = schedule;
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
        backupPrepareCommand = ''
          set -eu
          ${pkgs.coreutils}/bin/test -d ${lib.escapeShellArg path}
        '';
      };
    in {
      imports = [self.homeModules.backupMetrics];

      services.restic = {
        enable = true;
        backups = {
          sync = backup "sync" (folderPath "sync") "*-*-* 02:00:00";
          roms =
            (backup "roms" (folderPath "roms") "*-*-* 04:00:00")
            // {
              backupPrepareCommand = ''
                set -eu
                ${pkgs.util-linux}/bin/mountpoint -q /mnt/Storage
                ${pkgs.coreutils}/bin/test -d ${lib.escapeShellArg (folderPath "roms")}
              '';
            };
        };
      };
    };
  };
}
