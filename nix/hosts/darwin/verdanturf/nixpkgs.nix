{sharedPackageSets, ...}: {
  flake.darwinModules.verdanturf.nixpkgs = {
    hostPlatform = "aarch64-darwin";
    pkgs = sharedPackageSets.aarch64-darwin;
  };
}
