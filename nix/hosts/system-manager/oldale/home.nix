_: {
  flake.homeModules.oldale = {
    home.stateVersion = "26.05";

    targets.genericLinux.enable = true;
    systemd.user.startServices = "sd-switch";
  };
}
