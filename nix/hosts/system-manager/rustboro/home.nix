_: {
  flake.homeModules.rustboro = {config, ...}: {
    home.packages = [config.programs.home-manager.package];
    home.stateVersion = "26.05";

    targets.genericLinux.enable = true;
    systemd.user.startServices = "sd-switch";
  };
}
