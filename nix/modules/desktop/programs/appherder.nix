{inputs, ...}: {
  flake.homeModules.desktop = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.appherder.homeModules.appherder];

    config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.appherder = {
        enable = true;
        package = inputs.appherder.packages.${pkgs.stdenv.hostPlatform.system}.appherder.override {
          inherit (pkgs) dwarfs;
        };
      };

      services.appherder = {
        enable = true;
        upgrade.enable = true;
      };
    };
  };
}
