{
  inputs,
  lib,
  self,
  ...
}: {
  options.flake.systemModules.oldale = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake.systemConfigs.oldale = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.systemModules.systemManager
      self.systemModules.oldale
    ];
  };

  config.blzrd.nodes.oldale = {
    output = self.systemConfigs.oldale;
    type = "system-manager";
    user = "aly";
  };
}
