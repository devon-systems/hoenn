{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.tmux = {
      enable = true;
      package = inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.tmux;
    };
  };
}
