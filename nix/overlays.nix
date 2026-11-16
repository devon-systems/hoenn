_: {
  flake.overlays = {
    default = _final: prev: {
      # Remove after nixos-unstable includes dwarfs 0.15.10. Revisit after 2026-11-22.
      # https://github.com/NixOS/nixpkgs/pull/588348
      dwarfs = prev.dwarfs.overrideAttrs (_old: rec {
        version = "0.15.10";
        src = prev.fetchFromGitHub {
          owner = "mhx";
          repo = "dwarfs";
          tag = "v${version}";
          fetchSubmodules = true;
          hash = "sha256-eLFg4sjrGUgIzynmjOvnN4vYa6crfKmI5mZm211oZP8=";
        };
      });
    };
  };
}
