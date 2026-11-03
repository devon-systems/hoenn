_: {
  flake.homeModules.desktop = {pkgs, ...}: {
    home.packages = [pkgs.signal-desktop];
  };
}
