_: {
  flake.homeModules.syncthing = {lib, ...}: let
    inherit (lib) mkEnableOption mkOption types;

    deviceType = types.submodule {
      options = {
        id = mkOption {
          type = types.nonEmptyStr;
          description = "Syncthing device ID.";
        };

        introducer = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this device introduces other Syncthing peers.";
        };
      };
    };

    folderType = defaults:
      types.submodule ({name, ...}: {
        options = {
          enable = mkEnableOption "the ${name} Syncthing folder";

          path = mkOption {
            type = types.strMatching "(/|~/).*";
            default = defaults.path;
            description = "Absolute path or path relative to the home directory for this folder.";
          };

          id = mkOption {
            type = types.nonEmptyStr;
            default = defaults.id;
            description = "Syncthing folder ID, which must be identical on every peer.";
          };

          label = mkOption {
            type = types.nonEmptyStr;
            default = defaults.label or name;
            description = "Human-readable label for this folder in Syncthing.";
          };

          devices = mkOption {
            type = types.listOf types.nonEmptyStr;
            default = defaults.devices;
            description = "Names of the Syncthing devices that share this folder.";
          };

          ignorePatterns = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = defaults.ignorePatterns or null;
            description = "Patterns for files Syncthing must ignore in this folder.";
          };

          versioning = mkOption {
            type = types.nullOr (types.submodule {
              options = {
                type = mkOption {
                  type = types.enum ["external" "simple" "staggered" "trashcan"];
                  description = "Syncthing versioning strategy.";
                };

                params = mkOption {
                  type = types.attrsOf types.str;
                  default = {};
                  description = "Parameters for the selected versioning strategy.";
                };
              };
            });
            default = defaults.versioning or null;
            description = "Optional versioning configuration for this folder.";
          };
        };
      });
  in {
    options.hoenn.syncthing = {
      enable = mkEnableOption "Syncthing with Hoenn's shared folders";

      cert = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to this host's Syncthing certificate.";
      };

      key = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to this host's Syncthing private key.";
      };

      devices = mkOption {
        type = types.attrsOf deviceType;
        default = import ./_devices.nix;
        description = "Syncthing peers available to the managed folders.";
      };

      folders = {
        sync = mkOption {
          type = folderType {
            path = "~/Sync";
            id = "default";
            devices = ["fortree" "lilycove" "mauville" "pacifidlog" "petalburg" "rustboro" "sootopolis"];

            versioning = {
              type = "trashcan";
              params.cleanoutDays = "5";
            };
          };

          default = {};
          description = "Configuration for the shared Sync folder.";
        };

        roms = mkOption {
          type = folderType {
            path = "~/ROMs";
            id = "emudeck";
            devices = ["aynthor" "mauville" "pacifidlog" "petalburg"];
            ignorePatterns = ["androidapps" "emulators"];
          };

          default = {};
          description = "Configuration for the shared ROMs folder.";
        };
      };
    };
  };
}
