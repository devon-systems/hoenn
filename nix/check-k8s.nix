_: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.check-k8s = pkgs.writeShellApplication {
      name = "check-k8s";
      runtimeInputs = [
        (pkgs.python3.withPackages (python: [python.pyyaml]))
        pkgs.fluxcd
        pkgs.kustomize
        pkgs.kubernetes-helm
        pkgs.kubeconform
      ];
      text = ''
        exec python3 ${../scripts/check-k8s.py} --kubernetes-version ${lib.versions.majorMinor pkgs.k3s.version}.0 "$@"
      '';
    };
  };
}
