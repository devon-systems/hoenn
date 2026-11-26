{
  inputs,
  lib,
  self,
  ...
}: {
  options.flake.systemModules.rustboro = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake.systemConfigs.rustboro = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.systemModules.systemManager
      self.systemModules.rustboro
    ];
  };

  config.blzrd.nodes.rustboro = {
    output = self.systemConfigs.rustboro;
    type = "system-manager";
    user = "root";
  };
}
