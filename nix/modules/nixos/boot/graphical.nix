_: {
  flake.nixosModules.nixos = {
    boot = {
      consoleLogLevel = 0;

      kernelParams = [
        "quiet"
        "rd.systemd.show_status=auto"
        "udev.log_level=3"
      ];

      loader.timeout = 1;
      plymouth.enable = true;
    };
  };
}
