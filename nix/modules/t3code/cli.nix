{inputs, ...}: {
  flake.homeModules.t3codeCli = {pkgs, ...}: {
    home.packages = [inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.t3code];
  };
}
