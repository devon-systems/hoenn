{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.sootopolis = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.determinate.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.aly
      self.nixosModules.autoUpgrade
      self.nixosModules.comin
      self.nixosModules.default
      self.nixosModules.desktop
      self.nixosModules.homebrew
      self.nixosModules.nfsClient
      self.nixosModules.niri
      self.nixosModules.nixos
      self.nixosModules.observability
      self.nixosModules.sootopolis
      self.nixosModules.remoteBuilds
      self.nixosModules.tailscale
      self.nixosModules.thermald
      self.nixosModules.wireguardHoenn
    ];

    specialArgs = {inherit self;};
  };
}
