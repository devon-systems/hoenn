{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.fallarbor = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.determinate.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.autoUpgrade
      self.nixosModules.comin
      self.nixosModules.cosmic
      self.nixosModules.default
      self.nixosModules.dustin
      self.nixosModules.fallarbor
      self.nixosModules.google-chrome
      self.nixosModules.nixos
      self.nixosModules.observability
      self.nixosModules.thermald
      self.nixosModules.wireguardHoenn
    ];

    specialArgs = {inherit self;};
  };
}
