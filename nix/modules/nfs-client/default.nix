_: {
  flake.nixosModules.nfsClient = {pkgs, ...}: let
    nfsOptions = [
      "default"
      "fsc"
      "noatime"
      "nofail"
      "retrans=2"
      "rsize=1048576"
      "wsize=1048576"
      "x-systemd.after=network-online.target"
      "x-systemd.after=tailscaled.service"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=5s"
    ];

    nfsMount = path: {
      device = "goldenrod:${path}";
      fsType = "nfs";
      options = nfsOptions;
    };
  in {
    environment.systemPackages = [pkgs.nfs-utils];

    fileSystems = {
      "/mnt/Data" = nfsMount "/mnt/Data";
      "/mnt/Media" = nfsMount "/mnt/Media";
    };

    services.cachefilesd = {
      enable = true;
      extraConfig = ''
        brun 20%
        bcull 10%
        bstop 5%
      '';
    };
  };
}
