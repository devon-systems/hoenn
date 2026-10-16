{lib, ...}: {
  options.flake.darwinModules.zed-editor = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake.darwinModules.zed-editor = {
    homebrew.casks = ["zed"];
  };
}
