{lib, ...}: let
  alloyConfig = import ./_config.nix;
in {
  options.flake = {
    darwinModules.observability = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
    systemModules.observability = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
  };

  config.flake = {
    nixosModules.observability = {config, ...}: {
      imports = [./_filesystem-metrics.nix];

      services.prometheus.exporters.smartctl = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9633;
        maxInterval = "5m";
        extraFlags = ["--smartctl.powermode-check=standby"];
      };

      services.alloy = {
        enable = true;
        extraFlags = [
          "--disable-reporting"
          "--server.http.listen-addr=127.0.0.1:12345"
          "--storage.path=/var/lib/alloy"
        ];
      };
      environment.etc."alloy/config.alloy".text = alloyConfig {
        hostName = config.networking.hostName;
        isLinux = true;
        server =
          if config.networking.hostName == "mauville"
          then "127.0.0.1"
          else "mauville.hoenn";
      };
    };

    darwinModules.observability = {
      config,
      pkgs,
      ...
    }: let
      configuration = pkgs.writeText "config.alloy" (alloyConfig {
        hostName = config.networking.hostName;
        isLinux = false;
      });
    in {
      launchd.daemons.alloy = {
        script = ''
          /bin/mkdir -p /var/lib/alloy
          exec ${lib.getExe pkgs.grafana-alloy} run ${configuration} \
            --storage.path=/var/lib/alloy \
            --server.http.listen-addr=127.0.0.1:12345 \
            --disable-reporting
        '';
        serviceConfig = {
          KeepAlive = true;
          RunAtLoad = true;
          ProcessType = "Background";
          ThrottleInterval = 10;
        };
      };
    };

    systemModules.observability = {pkgs, ...}: let
      configuration = pkgs.writeText "config.alloy" (alloyConfig {
        hostName = "sootopolis";
        isLinux = true;
        # The system-manager output does not manage WireGuard or DNS.
        server = "mauville.narwhal-snapper.ts.net";
      });
    in {
      imports = [./_filesystem-metrics.nix];

      systemd.services.prometheus-smartctl-exporter = {
        description = "Collect SMART and NVMe drive health";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.prometheus-smartctl-exporter} --web.listen-address=127.0.0.1:9633 --smartctl.interval=5m --smartctl.powermode-check=standby";
          # NVMe controller nodes require root access on the unmanaged OS.
          User = "root";
          CapabilityBoundingSet = ["CAP_SYS_RAWIO" "CAP_SYS_ADMIN"];
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      systemd.services.alloy = {
        description = "Collect Hoenn desktop metrics and journals";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.grafana-alloy} run ${configuration} --storage.path=/var/lib/alloy --server.http.listen-addr=127.0.0.1:12345 --disable-reporting";
          DynamicUser = true;
          SupplementaryGroups = ["systemd-journal"];
          StateDirectory = "alloy";
          Restart = "always";
          RestartSec = 10;
        };
      };
    };
  };
}
