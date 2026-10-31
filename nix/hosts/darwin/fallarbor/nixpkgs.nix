{sharedPackageSets, ...}: {
  flake.darwinModules.fallarbor.nixpkgs = {
    hostPlatform = "aarch64-darwin";
    pkgs = sharedPackageSets.aarch64-darwin;
  };
}
