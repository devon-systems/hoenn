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
        # Upstream builds against its own pkgs; use ours to pick up the
        # dwarfs overlay.
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
