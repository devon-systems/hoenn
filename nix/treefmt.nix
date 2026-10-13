_: {
  perSystem = _: {
    treefmt.config = {
      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        prettier.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
        terraform.enable = true;
      };

      settings.excludes = [
        "secrets/**"
        "k8s/flux-system/gotk-components.yaml"
      ];
    };
  };
}
