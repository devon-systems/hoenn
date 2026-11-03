{self, ...}: {
  flake.homeModules.t3codeCli = {pkgs, ...}: {
    home.packages = [self.packages.${pkgs.stdenv.hostPlatform.system}.t3code];
  };
}
