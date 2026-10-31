{
  inputs,
  self,
  ...
}: {
  config = {
    flake.nixosConfigurations.mauville = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        inputs.determinate.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        self.nixosModules.aly
        self.nixosModules.autoUpgrade
        self.nixosModules.comin
        self.nixosModules.default
        self.nixosModules.k3s
        self.nixosModules.mauville
        self.nixosModules.nfsClient
        self.nixosModules.nixos
        self.nixosModules.observability
        self.nixosModules.tailscale
        self.nixosModules.wireguardHoenn
      ];

      specialArgs = {inherit self;};
    };

    blzrd.nodes.mauville = {
      output = self.nixosConfigurations.mauville.config.system.build.toplevel;
      type = "nixos";
      user = "root";
    };
  };
}
