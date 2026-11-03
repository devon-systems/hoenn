{self, ...}: {
  flake.homeModules.t3code = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.t3code = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop;
      mutableClientSettings = true;
      mutableKeybindings = true;
      mutableUserSettings = true;
    };

    # OAuth callbacks must launch T3 Code rather than bare Electron.
    xdg.desktopEntries."com.t3tools.T3Code" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      name = "T3 Code (Beta)";
      exec = "${config.programs.t3code.package}/bin/t3code-desktop %U";
      noDisplay = true;
      mimeType = ["x-scheme-handler/t3code"];
    };
  };
}
