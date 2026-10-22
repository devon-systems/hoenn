_: {
  flake.homeModules.syncthing = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkIf mkMerge;

    cfg = config.hoenn.syncthing;

    enabledFolder = folder:
      mkIf folder.enable {
        "${folder.path}" = {
          inherit (folder) devices id ignorePatterns label versioning;
        };
      };
  in {
    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.folders.sync.enable && cfg.folders.roms.enable && cfg.folders.sync.path == cfg.folders.roms.path);
          message = "hoenn.syncthing folders.sync and folders.roms must use different paths.";
        }
        {
          assertion = (cfg.cert == null) == (cfg.key == null);
          message = "hoenn.syncthing cert and key must be configured together.";
        }
      ];

      services.syncthing = {
        inherit (cfg) cert key;

        enable = true;
        overrideDevices = false;
        overrideFolders = false;

        settings = {
          devices =
            lib.mapAttrs (_: device: {
              inherit (device) id introducer;
            })
            cfg.devices;

          folders = mkMerge [
            (enabledFolder cfg.folders.sync)
            (enabledFolder cfg.folders.roms)
          ];
        };
      };
    };
  };
}
