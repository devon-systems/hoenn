{self, ...}: {
  flake.homeModules.t3code = {pkgs, ...}: {
    programs.t3code = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop;
      mutableClientSettings = true;
      mutableKeybindings = true;
      mutableUserSettings = true;
    };
  };
}
