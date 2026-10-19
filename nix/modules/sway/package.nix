{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    patchedSway = inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.sway;
    swayValidator = patchedSway.override {withBaseWrapper = false;};
  in {
    packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      sway = inputs.nix-wrapper-modules.lib.wrapPackage (
        {
          config,
          lib,
          ...
        }: {
          inherit pkgs;

          package = patchedSway;

          constructFiles.generatedConfig = {
            relPath = "${config.binName}-config";
            content = builtins.readFile ./config;
          };

          addFlag = [
            [
              "--config"
              config.constructFiles.generatedConfig.path
            ]
          ];

          prefixVar = [
            [
              "PATH"
              ":"
              (lib.makeBinPath [pkgs.noctalia])
            ]
          ];

          drv.installPhase = ''
            runHook preInstall
            export XDG_RUNTIME_DIR="$TMPDIR/sway-runtime"
            export WLR_BACKENDS=headless
            export WLR_RENDERER=pixman
            mkdir -m 700 "$XDG_RUNTIME_DIR"
            ${lib.getExe swayValidator} --validate --config ${config.constructFiles.generatedConfig.path}
            runHook postInstall
          '';

          filesToPatch = [
            "share/applications/*.desktop"
            "share/wayland-sessions/*.desktop"
          ];

          passthru.providedSessions = patchedSway.passthru.providedSessions;
        }
      );
    };
  };
}
