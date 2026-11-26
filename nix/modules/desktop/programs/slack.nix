{
  flake = {
    homeModules.desktop = {
      lib,
      pkgs,
      ...
    }: {
      home.packages = lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) pkgs.slack;
    };

    darwinModules.desktop = {
      homebrew.casks = ["slack"];
    };
  };
}
