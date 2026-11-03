_: {
  flake = {
    darwinModules.desktop = {pkgs, ...}: {
      environment.systemPackages = [pkgs.firefox];
    };

    nixosModules.desktop = {
      programs.firefox.enable = true;
    };
  };
}
