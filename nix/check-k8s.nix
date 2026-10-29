{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }: {
    packages.check-k8s = pkgs.writeShellApplication {
      name = "check-k8s";
      text = ''
        exec ${lib.getExe inputs.dvnpkgs.packages.${system}.check-k8s} --kubernetes-version ${lib.versions.majorMinor pkgs.k3s.version}.0 "$@"
      '';
    };
  };
}
