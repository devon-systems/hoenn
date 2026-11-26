{
  flake = {
    homeModules.desktop = {
      lib,
      pkgs,
      ...
    }: {
      home.packages = lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) pkgs.chatgpt;
    };

    darwinModules.desktop = {
      homebrew.casks = ["chatgpt"];
    };
  };
}
