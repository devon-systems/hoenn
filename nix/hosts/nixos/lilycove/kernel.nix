_: {
  flake.nixosModules.lilycove = {pkgs, ...}: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
