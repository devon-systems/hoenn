{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (let
      commonConfig = pkgs.writeText "niri-common-config.kdl" (builtins.readFile ./config.kdl);

      mkNiri = {
        shellConfig,
        shellName,
        shellPackage,
      }: let
        selectedShellConfig = pkgs.writeText "niri-${shellName}-config.kdl" (builtins.readFile shellConfig);
      in
        inputs.nix-wrapper-modules.wrappers.niri.wrap {
          inherit pkgs;

          "config.kdl".content = ''
            include "${commonConfig}"
            include "${selectedShellConfig}"
            include optional=true "~/.config/niri/config.kdl"
          '';

          prefixVar = [
            [
              "PATH"
              ":"
              (lib.makeBinPath [shellPackage])
            ]
          ];
        };
    in {
      niri = mkNiri {
        shellConfig = ./noctalia.kdl;
        shellName = "noctalia";
        shellPackage = pkgs.noctalia;
      };

      niri-dux = mkNiri {
        shellConfig = ./dux.kdl;
        shellName = "dux";
        shellPackage = pkgs.dux-shell;
      };
    });
  };
}
