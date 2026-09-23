{sharedPackageSets, ...}: {
  flake.nixosModules.lilycove.nixpkgs.pkgs = sharedPackageSets.x86_64-linux;
}
