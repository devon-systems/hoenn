{
  inputs,
  self,
  ...
}: {
  config.flake.nixosConfigurations.verdanturf = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = [
      inputs.apple-silicon.nixosModules.apple-silicon-support
      inputs.determinate.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.aly
      self.nixosModules.autoUpgrade
      self.nixosModules.comin
      self.nixosModules.default
      self.nixosModules.google-chrome
      self.nixosModules.hermesWebui
      self.nixosModules.niri
      self.nixosModules.nixos
      self.nixosModules.tailscale
      self.nixosModules.verdanturf
      self.nixosModules.zen
    ];

    specialArgs = {inherit self;};
  };
}
