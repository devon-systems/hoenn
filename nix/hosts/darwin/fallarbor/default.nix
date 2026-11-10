{
  lib,
  self,
  inputs,
  ...
}: {
  options.flake.darwinModules.fallarbor = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake = {
    darwinConfigurations.fallarbor = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        self.darwinModules.fallarbor
        inputs.sops-nix.darwinModules.sops
        self.darwinModules.comin
        self.darwinModules.default
        self.darwinModules.desktop
        self.darwinModules.darwin
        self.darwinModules.observability
        self.darwinModules.aly
        self.darwinModules.tailscale
        self.darwinModules.wireguardHoenn
      ];

      specialArgs = {inherit self;};
    };
  };

  config.blzrd.nodes.fallarbor = {
    output = self.darwinConfigurations.fallarbor.config.system.build.toplevel;
    type = "darwin";
    user = "aly";
  };
}
