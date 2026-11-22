{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (let
      commonConfig = pkgs.writeText "hyprland-common-config.lua" (builtins.readFile ./config.lua);

      mkHyprland = {stacking}:
        inputs.nix-wrapper-modules.wrappers.hyprland.wrap {
          inherit pkgs;

          configFile = ''
            dofile("${commonConfig}")
            dofile("${./noctalia.lua}")

            -- Optional user overrides. Requiring an explicit path makes Hyprland
            -- reload when the file changes.
            local userConfigDir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
            ${lib.optionalString stacking ''
              hl.plugin.load("${pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so")
              dofile("${./stacking.lua}")(userConfigDir)
            ''}
            local userConfig = io.open(userConfigDir .. "/hyprland.lua")

            if userConfig then
              userConfig:close()
              package.path = userConfigDir .. "/?.lua;" .. userConfigDir .. "/?/init.lua;" .. package.path
              require(userConfigDir .. "/hyprland.lua")
            end
          '';

          prefixVar = [
            [
              "PATH"
              ":"
              (lib.makeBinPath [pkgs.noctalia])
            ]
          ];

          # Sessions launch start-hyprland, which otherwise finds Hyprland on
          # PATH and can skip this wrapper.
          wrapperVariants.start-hyprland = {
            mirror = false;
            flags."--path" = "${placeholder "out"}/bin/Hyprland";
          };

          filesToPatch = [
            "share/applications/*.desktop"
            "share/wayland-sessions/*.desktop"
          ];
        };
    in {
      hyprland = mkHyprland {stacking = false;};
      hyprland-stacking = mkHyprland {stacking = true;};
    });
  };
}
