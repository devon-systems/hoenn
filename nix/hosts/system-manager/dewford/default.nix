{
  inputs,
  lib,
  self,
  ...
}: {
  options.flake.systemModules.dewford = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake.systemConfigs.dewford = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.systemModules.systemManager
      self.systemModules.dewford
    ];
  };

  config.blzrd.nodes.dewford = {
    output = self.systemConfigs.dewford;
    type = "system-manager";
    user = "aly";
  };
}
