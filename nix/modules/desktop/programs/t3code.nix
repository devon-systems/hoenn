{inputs, ...}: {
  flake.homeModules.desktop = {pkgs, ...}: {
    programs.t3code = {
      enable = true;
      package = inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop;
      mutableClientSettings = true;
      mutableKeybindings = true;
      mutableUserSettings = true;
    };
  };
}
