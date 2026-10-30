_: {
  flake.nixosModules.lavaridge = {
    disko.devices.disk.main = {
      device = "/dev/disk/by-id/nvme-SK_hynix_PC801_HFS002TEJ9X101N_BDE4N54161OA05A2V";
      type = "disk";

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";

            content = {
              format = "vfat";
              mountOptions = ["umask=0077"];
              mountpoint = "/boot";
              type = "filesystem";
            };
          };

          cryptroot = {
            size = "100%";

            content = {
              name = "cryptroot";
              type = "luks";

              content = {
                extraArgs = ["-f"];
                type = "btrfs";

                subvolumes = {
                  "@" = {
                    mountOptions = ["compress=zstd" "noatime"];
                    mountpoint = "/";
                  };

                  "@home" = {
                    mountOptions = ["compress=zstd" "noatime"];
                    mountpoint = "/home";
                  };

                  "@nix" = {
                    mountOptions = ["compress=zstd" "noatime"];
                    mountpoint = "/nix";
                  };
                };
              };

              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
            };
          };
        };
      };
    };
  };
}
