{
  flake = {
    homeModules.desktop = {
      lib,
      pkgs,
      ...
    }: {
      home.packages = lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) pkgs.signal-desktop;
    };

    darwinModules.desktop = {
      homebrew.casks = ["signal"];
    };
  };
}
