_: {
  flake.nixosModules.verdanturf = {lib, ...}: {
    boot = {
      extraModprobeConfig = ''
        options hid_apple iso_layout=0
      '';

      lanzaboote.enable = lib.mkForce false;

      loader = {
        efi.canTouchEfiVariables = false;
        systemd-boot.enable = lib.mkOverride 40 true;
      };
    };

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    hardware.asahi = {
      enable = true;
      extractPeripheralFirmware = false;
    };

    networking.networkmanager.wifi.backend = "iwd";
  };
}
