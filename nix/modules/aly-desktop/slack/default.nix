_: {
  flake.homeModules.aly-desktop = {pkgs, ...}: {
    home.packages = [pkgs.slack];
  };
}
