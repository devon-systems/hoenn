{
  lib,
  self,
  inputs,
  ...
}: {
  options.flake.darwinModules.fortree = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake = {
    darwinConfigurations.fortree = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        self.darwinModules.fortree
        inputs.sops-nix.darwinModules.sops
        self.darwinModules.comin
        self.darwinModules.default
        self.darwinModules.darwin
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
