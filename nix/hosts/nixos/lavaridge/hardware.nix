_: {
  flake.nixosModules.lavaridge = {pkgs, ...}: {
    environment.systemPackages = [pkgs.nvtopPackages.amd];
  };
}
