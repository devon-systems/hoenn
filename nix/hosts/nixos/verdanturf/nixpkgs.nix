{sharedPackageSets, ...}: {
  flake.nixosModules.verdanturf.nixpkgs.pkgs = sharedPackageSets.aarch64-linux;
}
