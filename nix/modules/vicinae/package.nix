_: {
  perSystem = {pkgs, ...}: {
    packages.vicinae-pdsls = pkgs.buildNpmPackage {
      name = "pdsls";
      src =
        pkgs.fetchFromGitHub {
          owner = "raycast";
          repo = "extensions";
          rev = "b8d63f2c8578215e2d7d5c25784245bca8c3bf4a";
          hash = "sha256-0b50Pc/V8EVlHspsZ3V5Wk/qCcGmjWAtfRVmIjJaCWg=";
          sparseCheckout = ["/extensions/pdsls"];
        }
        + "/extensions/pdsls";
      npmDepsHash = "sha256-LcB3a77R1cRuOEfKyQWiHqZeG9bzWiJsixbZs6wsrjs=";
      dontNpmInstall = true;
      buildPhase = ''
        runHook preBuild
        npm run build -- -o "$out"
        runHook postBuild
      '';
      dontInstall = true;
    };
  };
}
