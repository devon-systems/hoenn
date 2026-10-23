{pkgs, ...}: {
  systemd.services.observability-canary = {
    description = "Emit a log collection heartbeat";
    serviceConfig.Type = "oneshot";
    script = ''
      echo "observability_canary timestamp=$(${pkgs.coreutils}/bin/date +%s)"
    '';
  };
  systemd.timers.observability-canary = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
    };
  };
}
