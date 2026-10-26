_: {
  flake.nixosModules.nixos = {
    lib,
    pkgs,
    ...
  }: {
    programs.appimage = {
      enable = true;
      binfmt = true;
      package = let
        upstreamAppimageRun = pkgs.appimage-run;

        anylinuxAwareAppimageRun = pkgs.writeShellApplication {
          name = "appimage-run";

          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
          ];

          text = ''
            upstream_appimage_run=${lib.escapeShellArg (lib.getExe upstreamAppimageRun)}

            if [[ $# -eq 0 || $1 == -* ]]; then
              exec "$upstream_appimage_run" "$@"
            fi

            appimage_path=$(realpath "$1")
            shift

            if ! grep --binary-files=text --max-count=1 --quiet 'URUNTIME_EXTRACT=' "$appimage_path"; then
              exec "$upstream_appimage_run" "$appimage_path" "$@"
            fi

            image_hash=$(sha256sum "$appimage_path" | cut --delimiter=' ' --fields=1)
            cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/appimage-run/uruntime"
            executable_path="$cache_root/$image_hash/$(basename "$appimage_path")"

            if [[ ! -x $executable_path ]]; then
              install --directory "$(dirname "$executable_path")"
              temporary_path=$(mktemp "$(dirname "$executable_path")/.uruntime.XXXXXX")
              cp --reflink=auto --preserve=mode "$appimage_path" "$temporary_path"
              printf '\0' | dd of="$temporary_path" bs=1 seek=8 conv=notrunc status=none
              chmod u+x "$temporary_path"
              mv --force "$temporary_path" "$executable_path"
            fi

            exec "$executable_path" "$@"
          '';
        };
      in
        upstreamAppimageRun.overrideAttrs (previous: {
          extraInstallCommands =
            (previous.extraInstallCommands or "")
            + ''
              rm "$out/bin/appimage-run"
              ln --symbolic ${anylinuxAwareAppimageRun}/bin/appimage-run "$out/bin/appimage-run"
            '';
        });
    };
  };
}
