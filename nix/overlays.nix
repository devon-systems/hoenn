_: {
  flake.overlays = {
    default = final: prev: {
      # nixpkgs builds aws-lc-sys against a system AWS-LC, which cargo-bundle
      # does not provide on Darwin. Drop once NixOS/nixpkgs#584581 reaches
      # nixos-unstable.
      cargo-bundle = prev.cargo-bundle.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.pkg-config];
        buildInputs = (old.buildInputs or []) ++ [final.aws-lc];
      });

      # nixpkgs sets LIBGIT2_NO_VENDOR for Rust builds, but himalaya does not
      # provide a system libgit2. Drop once NixOS/nixpkgs#584922 reaches
      # nixos-unstable.
      himalaya = prev.himalaya.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [final.libgit2 final.sqlite];
      });

      # Same aws-lc-sys change: tectonic only provides OpenSSL, so the build
      # cannot find a system AWS-LC. Drop once nixpkgs adds aws-lc to it.
      tectonic-unwrapped = prev.tectonic-unwrapped.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [final.aws-lc];
      });
    };
  };
}
