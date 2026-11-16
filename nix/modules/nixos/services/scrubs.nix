_: {
  flake.nixosModules.nixos = {
    config,
    lib,
    ...
  }: {
    services.btrfs.autoScrub.enable = lib.any (fs: fs.fsType == "btrfs") (lib.attrValues config.fileSystems);
  };
}
