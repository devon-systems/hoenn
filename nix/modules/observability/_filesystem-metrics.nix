{pkgs, ...}: {
  systemd.services.hoenn-btrfs-metrics = {
    description = "Publish Btrfs scrub results and device error counters";
    wantedBy = ["multi-user.target"];
    before = ["alloy.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${../../../scripts/btrfs-metrics.py} --directory /var/lib/hoenn-metrics/btrfs";
      StateDirectory = "hoenn-metrics/btrfs";
      StateDirectoryMode = "0755";
      ProtectSystem = "strict";
      ReadWritePaths = ["/var/lib/hoenn-metrics/btrfs"];
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.hoenn-btrfs-metrics = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
    };
  };
}
