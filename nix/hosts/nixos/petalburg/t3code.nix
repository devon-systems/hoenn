_: {
  flake.nixosModules.petalburg = {config, ...}: {
    users.users.aly.linger = true;

    # Keep the existing Tailscale Serve endpoints on 443 and 8788.
    systemd.services.t3code-tailscale = {
      description = "Tailscale HTTPS access to T3 Code";
      wantedBy = ["multi-user.target"];
      after = ["tailscaled.service" "network-online.target"];
      wants = ["network-online.target"];
      requires = ["tailscaled.service"];
      unitConfig.StartLimitIntervalSec = 0;

      serviceConfig = {
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --https=8443 --yes http://127.0.0.1:3773";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
