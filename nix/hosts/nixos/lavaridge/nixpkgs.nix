{sharedPackageSets, ...}: {
  flake.nixosModules.lavaridge.nixpkgs.pkgs = sharedPackageSets.x86_64-linux;
}
