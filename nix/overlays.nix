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
    };
  };
}
