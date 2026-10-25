_: {
  perSystem = {pkgs, ...}: {
    checks.backup-metrics = pkgs.runCommand "backup-metrics-tests" {nativeBuildInputs = [pkgs.python3];} ''
      cp ${../scripts/backup-metrics.py} backup-metrics.py
      cp ${../scripts/test-backup-metrics.py} test-backup-metrics.py
      python3 test-backup-metrics.py
      touch "$out"
    '';
  };
}
