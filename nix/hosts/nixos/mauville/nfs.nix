_: {
  flake.nixosModules.mauville = {
    services.nfs.server = {
      enable = true;
      exports = ''
        /mnt/Storage 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0)
      '';
    };

    networking.firewall = {
      allowedTCPPorts = [2049];
      allowedUDPPorts = [2049];
    };
  };
}
