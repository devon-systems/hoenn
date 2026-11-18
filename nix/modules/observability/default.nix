{
  inputs,
  lib,
  ...
}: let
  alloyConfig = import ./_config.nix;
in {
  options.flake = {
    darwinModules.observability = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
  };

  config.flake = {
    nixosModules.observability = {config, ...}: {
      imports = [(import ./_filesystem-metrics.nix {inherit inputs;}) ./_canary.nix];

      services.prometheus.exporters.smartctl = {
        enable = true;
        listenAddress = "127.0.0.1";
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
        cominPort =
          if config.services.comin.enable
          then config.services.comin.exporter.port
          else null;
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
        server = "mauville.narwhal-snapper.ts.net";
        cominPort =
          if config.services.comin.enable
          then config.services.comin.exporter.port
          else null;
      });
    in {
      launchd.daemons.observability-canary = {
        script = ''
          echo "observability_canary timestamp=$(${pkgs.coreutils}/bin/date +%s)"
        '';
        serviceConfig = {
          RunAtLoad = true;
          StartInterval = 60;
          StandardOutPath = "/var/log/observability-canary.log";
          StandardErrorPath = "/var/log/observability-canary.log";
        };
      };
      system.newsyslog.enable = true;
      system.newsyslog.files.observability = [
        {
          logfilename = "/var/log/observability-canary.log";
          count = 7;
          size = "1024";
          flags = ["N" "Z"];
        }
      ];

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
  };
}
