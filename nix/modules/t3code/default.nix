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
    # Electron writes a user-local handler that otherwise shadows the profile entry.
    xdg.dataFile."applications/com.t3tools.T3Code.desktop" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source = "${config.home.path}/share/applications/com.t3tools.T3Code.desktop";
      force = true;
      onChange = ''
        ${pkgs.desktop-file-utils}/bin/update-desktop-database ${lib.escapeShellArg "${config.xdg.dataHome}/applications"}
      '';
    };
  };
}
