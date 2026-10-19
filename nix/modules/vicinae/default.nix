{inputs, ...}: {
  flake.homeModules.vicinae = {
    lib,
    pkgs,
    ...
  }: {
    programs.vicinae = {
      enable = true;
      enableFirefoxIntegration = true;
      mutableSettings = true;
      extensions = [
        inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.vicinae-pdsls
      ];

      settings = {
        font = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
}
