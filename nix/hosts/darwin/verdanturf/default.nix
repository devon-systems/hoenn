{
  lib,
  self,
  inputs,
  ...
}: {
  options.flake.darwinModules.verdanturf = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake = {
    darwinConfigurations.verdanturf = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        self.darwinModules.verdanturf
        inputs.sops-nix.darwinModules.sops
        self.darwinModules.comin
        self.darwinModules.default
        self.darwinModules.darwin
        self.darwinModules.observability
        self.darwinModules.aly
        self.darwinModules.tailscale
        self.darwinModules.wireguardHoenn
        self.darwinModules.zen
        self.darwinModules.zed-editor
      ];

      specialArgs = {inherit self;};
    };
  };
}
