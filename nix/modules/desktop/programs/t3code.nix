{inputs, ...}: {
  flake = {
    homeModules.desktop = {pkgs, ...}: {
      programs.t3code = {
        enable = true;
        package =
          if pkgs.stdenv.hostPlatform.isDarwin
          then null
          else inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop;
        mutableClientSettings = true;
        mutableKeybindings = true;
        mutableUserSettings = true;
      };
    };

    darwinModules.desktop = {
      homebrew.casks = ["t3-code"];
    };
  };
}
