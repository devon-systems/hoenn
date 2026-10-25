_: {
  flake.homeModules.signal-desktop = {pkgs, ...}: {
    home.packages = [pkgs.signal-desktop];
  };
}
