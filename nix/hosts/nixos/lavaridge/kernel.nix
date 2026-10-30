_: {
  flake.nixosModules.lavaridge = {pkgs, ...}: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
