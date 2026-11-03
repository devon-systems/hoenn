_: {
  flake.homeModules.desktop = {pkgs, ...}: {
    home.packages = [pkgs.slack];
  };
}
