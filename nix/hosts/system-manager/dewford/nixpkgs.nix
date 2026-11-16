{sharedPackageSets, ...}: {
  flake.systemModules.dewford = {lib, ...}: {
    _module.args.pkgs = lib.mkForce sharedPackageSets.x86_64-linux;
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
