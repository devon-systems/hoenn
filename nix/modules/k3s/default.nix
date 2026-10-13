_: {
  flake.nixosModules.k3s = {
    config,
    self,
    ...
  }: {
    sops.secrets.k3s-token = {
      sopsFile = self + "/secrets/k3s.yaml";
      key = "TOKEN";
      mode = "0400";
    };

    services.k3s = {
      enable = true;
      tokenFile = config.sops.secrets.k3s-token.path;
      extraFlags = ["--flannel-iface=hoenn"];

      # Leave ordinary pods their usual 30-second termination budget.
      gracefulNodeShutdown = {
        enable = true;
        shutdownGracePeriod = "45s";
        shutdownGracePeriodCriticalPods = "10s";
      };
    };

    systemd.services.k3s = {
      after = ["wireguard-hoenn.target"];
      wants = ["wireguard-hoenn.target"];
    };
  };
}
