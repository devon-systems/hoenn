_: {
  flake = {
    nixosModules.desktop = {pkgs, ...}: {
      environment.systemPackages = [pkgs.google-chrome];
    };

    darwinModules.desktop = {
      homebrew.casks = ["google-chrome"];
    };
  };
}
