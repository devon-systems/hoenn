{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    hosts = lib.mapAttrs (_: host: host.config) self.nixosConfigurations;
    prometheusHosts = lib.filterAttrs (_: config: config.services.prometheus.enable) hosts;
    ruleFiles = lib.concatLists (lib.mapAttrsToList (host: config:
      config.services.prometheus.ruleFiles
      ++ lib.imap0 (index: rules: pkgs.writeText "prometheus-${host}-${toString index}.yaml" rules) config.services.prometheus.rules)
    prometheusHosts);
    alloyHosts = lib.filterAttrs (_: config: config.services.alloy.enable) hosts;
    alloyConfigs = lib.mapAttrsToList (host: config:
      pkgs.linkFarm "alloy-${host}" (lib.mapAttrsToList (name: file: {
        name = lib.removePrefix "alloy/" name;
        path = file.source;
      }) (lib.filterAttrs (name: file: file.enable && lib.hasPrefix "alloy/" name && lib.hasSuffix ".alloy" name) config.environment.etc)))
    alloyHosts;
    # Validate both desktop variants on the Linux CI runner.
    alloyConfig = import ./modules/observability/_config.nix;
    darwin = self.darwinConfigurations.verdanturf.config;
    desktopConfigs = [
      (pkgs.writeText "alloy-darwin.alloy" (alloyConfig {
        hostName = darwin.networking.hostName;
        isLinux = false;
        cominPort =
          if darwin.services.comin.enable
          then darwin.services.comin.exporter.port
          else null;
        server = "mauville.narwhal-snapper.ts.net";
      }))
      (pkgs.writeText "alloy-system-manager.alloy" (alloyConfig {
        hostName = "sootopolis";
        isLinux = true;
        server = "mauville.narwhal-snapper.ts.net";
      }))
    ];
  in {
    checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      prometheus-rules =
        pkgs.runCommand "prometheus-rules" {
          nativeBuildInputs = [pkgs.prometheus.cli];
        } ''
          promtool check rules ${lib.escapeShellArgs (map toString ruleFiles)}
          touch "$out"
        '';

      alloy-config =
        pkgs.runCommand "alloy-config" {
          nativeBuildInputs = [pkgs.grafana-alloy];
        } ''
          ${lib.concatMapStringsSep "\n" (config: "alloy validate ${lib.escapeShellArg (toString config)}") (alloyConfigs ++ desktopConfigs)}
          alloy validate ${../k8s/alloy/config.alloy}
          touch "$out"
        '';
    };
  };
}
