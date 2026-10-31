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
      lib,
      self,
      ...
    }: {
      networking.firewall = {
        allowedUDPPorts = [config.services.tailscale.port];
        trustedInterfaces = [config.services.tailscale.interfaceName];
      };

      sops.secrets.tailscale-auth-key.sopsFile = self + "/secrets/tailscale.yaml";

      # Tailscale SSH uses login's PAM stack without a login password.
      # Skip only the following keyring hook for remote sessions so a stuck
      # desktop keyring cannot block SSH. Keep local console unlocking.
      security.pam.services.login.rules.session.skip_remote_keyring = lib.mkIf config.security.pam.services.login.enableGnomeKeyring {
        order = config.security.pam.services.login.rules.session.gnome_keyring.order - 1;
        control = "[success=1 default=ignore]";
        modulePath = "${config.security.pam.package}/lib/security/pam_succeed_if.so";
        args = ["quiet" "rhost" "=~" "?*"];
      };

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
