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

    checks.k8s-bundle =
      pkgs.runCommand "k8s-bundle-tests" {
        nativeBuildInputs = [(pkgs.python3.withPackages (python: [python.pyyaml]))];
      } ''
        cp ${../scripts/check-k8s.py} check-k8s.py
        cp ${../scripts/test-k8s-bundle.py} test-k8s-bundle.py
        cp ${../k8s/flux-system/gotk-components.yaml} gotk-components.yaml
        python3 test-k8s-bundle.py
        touch "$out"
      '';
  };
}
