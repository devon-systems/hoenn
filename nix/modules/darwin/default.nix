{lib, ...}: {
  options.flake.darwinModules = {
    default = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };

    desktop = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };

    darwin = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };

    google-chrome = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };

    aly = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };

    zen = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
  };
}
