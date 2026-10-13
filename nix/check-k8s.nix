_: {
  perSystem = {pkgs, ...}: {
    packages.check-k8s = pkgs.writeShellApplication {
      name = "check-k8s";
      runtimeInputs = [
        (pkgs.python3.withPackages (python: [python.pyyaml]))
        pkgs.kustomize
        pkgs.kubernetes-helm
        pkgs.kubeconform
      ];
      text = ''
        exec python3 ${../scripts/check-k8s.py} "$@"
      '';
    };
  };
}
