_: {
  flake.nixosModules.petalburg = {
    networking = {
      nftables.enable = true;
      firewall.interfaces.incusbr0 = {
        allowedTCPPorts = [53];
        allowedUDPPorts = [53 67];
      };
    };

    # Docker must not drop forwarding traffic owned by Incus.
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    virtualisation.docker.daemon.settings."ip-forward-no-drop" = true;

    virtualisation.incus = {
      enable = true;
      preseed = {
        networks = [
          {
            name = "incusbr0";
            type = "bridge";
            config = {
              "ipv4.address" = "10.90.0.1/24";
              "ipv4.nat" = "true";
              "ipv6.address" = "none";
            };
          }
        ];
        storage_pools = [
          {
            name = "dev";
            driver = "btrfs";
            config.source = "/var/lib/incus/storage-pools/dev";
          }
        ];
      };
    };
  };
}
