_: {
  flake.nixosModules.lilycove = {self, ...}: {
    hardware.facter.reportPath = self + "/nix/hosts/nixos/lilycove/facter.json";
  };
}
