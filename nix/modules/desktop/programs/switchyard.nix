{inputs, ...}: {
  flake.homeModules.desktop = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.switchyard.homeManagerModules.switchyard];

    config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.switchyard.enable = true;
    };
  };
}
