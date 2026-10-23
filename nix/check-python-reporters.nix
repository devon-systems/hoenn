_: {
  perSystem = {pkgs, ...}: {
    checks.python-reporters =
      pkgs.runCommand "python-reporters" {
        nativeBuildInputs = [pkgs.ruff pkgs.ty];
      } ''
        cp ${../scripts/backup-metrics.py} backup-metrics.py
        cp ${../scripts/btrfs-metrics.py} btrfs-metrics.py
        ruff format --isolated --check --target-version py313 backup-metrics.py btrfs-metrics.py
        ruff check --isolated --target-version py313 --select E4,E7,E9,F,I,UP,B backup-metrics.py btrfs-metrics.py
        ty check --python-version 3.13 backup-metrics.py btrfs-metrics.py
        touch "$out"
      '';
  };
}
