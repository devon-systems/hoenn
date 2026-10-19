{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    home.packages = [inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.tg];
  };
}
