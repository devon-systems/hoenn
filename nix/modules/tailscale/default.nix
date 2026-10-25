{lib, ...}: {
  options.flake.darwinModules.tailscale = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake = {
    darwinModules.tailscale = {
      networking = {
        # Explicitly manage these
        knownNetworkServices = [
          "Wi-Fi"
          "Ethernet Adaptor"
          "Thunderbolt Ethernet"
        ];

        # Otherwise tailscale ssh only works with FQDNs
        search = ["narwhal-snapper.ts.net"];
      };

      services.tailscale = {
        enable = true;
        # Needs a declared DNS provider in Tailscale's admin panel
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
