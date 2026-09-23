{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.lilycove = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.determinate.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.aly
      self.nixosModules.autoUpgrade
      self.nixosModules.comin
      self.nixosModules.default
      self.nixosModules.google-chrome
      self.nixosModules.niri
      self.nixosModules.nixos
      self.nixosModules.lilycove
      self.nixosModules.tailscale
      self.nixosModules.wireguardHoenn
      self.nixosModules.zen
    ];

    specialArgs = {inherit self;};
  };
}
