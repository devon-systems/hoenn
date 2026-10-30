_: {
  flake.nixosModules.lavaridge = {self, ...}: {
    hardware.facter.reportPath = self + "/nix/hosts/nixos/lavaridge/facter.json";
  };
}
