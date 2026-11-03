{self, ...}: {
  flake.homeModules.aly-desktop = {pkgs, ...}: {
    programs.t3code = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop;
      mutableClientSettings = true;
      mutableKeybindings = true;
      mutableUserSettings = true;
    };
  };
}
