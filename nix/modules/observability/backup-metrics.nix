_: let
  backupReporter = pkgs:
    pkgs.writeShellApplication {
      name = "hoenn-backup-metrics";
      runtimeInputs = [pkgs.python3 pkgs.systemd pkgs.coreutils];
      text = ''exec python3 ${../../../scripts/backup-metrics.py} "$@"'';
    };
in {
  flake.nixosModules.observability = {
    config,
    lib,
    pkgs,
    ...
  }: let
    directory = "/var/lib/hoenn-metrics/backups-system";
    jobs = builtins.attrNames config.services.restic.backups;
    reporter = backupReporter pkgs;
    command = "${lib.getExe reporter} --directory ${directory} --scope system --owner root --file-prefix backup-";
  in {
    systemd.services = lib.mkMerge [
      # Report after the complete unit, including Restic's cleanup commands.
      (lib.mapAttrs' (job: _:
        lib.nameValuePair "restic-backups-${job}" {
          onSuccess = ["hoenn-backup-metrics-${job}.service"];
          onFailure = ["hoenn-backup-metrics-${job}.service"];
          serviceConfig.ExecStartPre = lib.mkBefore ["-${command} --start ${lib.escapeShellArg job}"];
        })
      config.services.restic.backups)
      (lib.listToAttrs (map (job:
        lib.nameValuePair "hoenn-backup-metrics-${job}" {
          description = "Publish completed backup result for ${job}";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${command} ${lib.escapeShellArg job}";
          };
        })
      jobs))
      {
        hoenn-backup-metrics-seed = {
          description = "Initialize backup job inventory";
          wantedBy = ["multi-user.target"];
          before = ["alloy.service"] ++ map (job: "restic-backups-${job}.service") jobs;
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "hoenn-metrics/backups-system";
            ExecStart = "${command} --seed ${lib.escapeShellArgs jobs}";
          };
        };
      }
    ];
  };

  flake.homeModules.backupMetrics = {
    config,
    lib,
    pkgs,
    ...
  }: let
    jobs = builtins.attrNames config.services.restic.backups;
    owner = config.home.username;
    directory = "/var/lib/hoenn-metrics/backups-user-${owner}";
    reporter = backupReporter pkgs;
    command = "${lib.getExe reporter} --directory ${directory} --scope user --owner ${lib.escapeShellArg owner} --file-prefix backup-";
  in
    lib.mkIf (config.services.restic.enable && jobs != []) {
      systemd.user.services = lib.mkMerge [
        (lib.mapAttrs' (job: _:
          lib.nameValuePair "restic-backups-${job}" {
            # Home Manager's Restic module owns ExecStartPre.
            Service.ExecCondition = "-${command} --start ${lib.escapeShellArg job}";
            Unit = {
              OnSuccess = ["hoenn-backup-metrics-${job}.service"];
              OnFailure = ["hoenn-backup-metrics-${job}.service"];
            };
          })
        config.services.restic.backups)
        (lib.listToAttrs (map (job:
          lib.nameValuePair "hoenn-backup-metrics-${job}" {
            Unit.Description = "Publish completed backup result for ${job}";
            Service = {
              Type = "oneshot";
              ExecStart = "${command} ${lib.escapeShellArg job}";
            };
          })
        jobs))
        {
          hoenn-backup-metrics-seed = {
            Unit = {
              Description = "Initialize user backup inventory";
              Before = map (job: "restic-backups-${job}.service") jobs;
            };
            Install.WantedBy = ["default.target"];
            Service = {
              Type = "oneshot";
              ExecStart = "${command} --seed ${lib.escapeShellArgs jobs}";
            };
          };
        }
      ];
    };
}
