{
  inputs,
  lib,
  self,
  ...
}: {
  options.flake.systemModules.sootopolis = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake.systemConfigs.sootopolis = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      self.systemModules.autoUpgrade
      self.systemModules.systemManager
      self.systemModules.observability
      self.systemModules.sootopolis
    ];
  };
}
