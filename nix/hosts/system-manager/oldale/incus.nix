_: {
  flake.nixosModules.oldaleVm = {
    virtualisation.incus.preseed.profiles = [
      {
        name = "oldale";

        config = {
          "boot.autostart" = "true";
          "limits.cpu" = "4";
          "limits.memory" = "8GiB";
        };

        devices = {
          eth0 = {
            type = "nic";
            name = "eth0";
            network = "incusbr0";
          };

          root = {
            type = "disk";
            path = "/";
            pool = "dev";
            size = "100GiB";
          };
        };
      }
    ];
  };
}
