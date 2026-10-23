_: {
  perSystem = {pkgs, ...}: {
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

      settings.formatter.python-reporters = {
        command = "${pkgs.ruff}/bin/ruff";
        options = ["format" "--isolated" "--target-version" "py313"];
        includes = ["scripts/backup-metrics.py" "scripts/btrfs-metrics.py"];
      };

      settings.excludes = [
        "secrets/**"
        "k8s/flux-system/gotk-components.yaml"
      ];
    };
  };
}
