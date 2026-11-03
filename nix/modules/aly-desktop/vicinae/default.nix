{inputs, ...}: {
  flake.homeModules.aly-desktop = {
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.vicinae = {
        enable = true;
        enableFirefoxIntegration = true;
        mutableSettings = true;
        extensions = [
          inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.vicinae-extensions-pdsls
        ];

        settings = {
          font = {
            rendering = "qt";
            normal.family = "Adwaita Sans";
          };
          launcher_window = {
            compact_mode.enabled = true;
            material = "blur";
          };
        };
      };
    };
  };
}
