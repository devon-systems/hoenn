{lib, ...}: {
  options.flake.darwinModules.tailscale = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake = {
    darwinModules.tailscale = {
      networking = {
        knownNetworkServices = [
          "Wi-Fi"
          "Ethernet Adaptor"
          "Thunderbolt Ethernet"
        ];

        # Resolve short hostnames for Tailscale SSH.
        search = ["narwhal-snapper.ts.net"];
      };

      services.tailscale = {
        enable = true;
        # Requires a DNS provider in the tailnet configuration.
        overrideLocalDns = true;
      };
    };

    nixosModules.tailscale = {
      config,
      self,
      ...
    }: {
      networking.firewall = {
        allowedUDPPorts = [config.services.tailscale.port];
        trustedInterfaces = [config.services.tailscale.interfaceName];
      };

      sops.secrets.tailscale-auth-key.sopsFile = self + "/secrets/tailscale.yaml";

      services.tailscale = {
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        enable = true;
        extraUpFlags = ["--ssh" "--accept-routes"];
        openFirewall = true;
        useRoutingFeatures = "both";
      };
    };
  };
}
