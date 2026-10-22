_: {
  flake.homeModules.slack = {pkgs, ...}: {
    home.packages = [pkgs.slack];
  };
}
