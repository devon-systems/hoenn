_: {
  flake.homeModules.aly = {pkgs, ...}: {
    home.packages = [pkgs.muse-code];
  };
}
