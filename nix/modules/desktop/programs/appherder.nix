{inputs, ...}: {
  flake.homeModules.desktop = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.appherder.homeModules.appherder];

    config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.appherder.enable = true;

      services.appherder = {
        enable = true;
        upgrade.enable = true;
      };
    };
  };
}
