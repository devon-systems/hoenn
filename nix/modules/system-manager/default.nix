{lib, ...}: {
  options.flake.systemConfigs = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.package;
    default = {};
  };

  options.flake.systemModules = {
    default = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };

    systemManager = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
  };
}
