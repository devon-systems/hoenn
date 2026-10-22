_: {
  flake.nixosModules.wireguardHoennLan = {
    config,
    pkgs,
    ...
  }: let
    interface = config.networking.wireguard.interfaces.hoenn;
  in {
    networking.firewall.allowedUDPPorts = [interface.listenPort];

    networking.wireguard.interfaces.hoenn = {
      listenPort = 51821;
      fwMark = "51821";

      # Keep WireGuard UDP on connected networks ahead of Tailscale subnet routes.
      postSetup = ''
        ${pkgs.iproute2}/bin/ip -4 rule add priority 5201 fwmark ${interface.fwMark} lookup main suppress_prefixlength 0
      '';
      postShutdown = ''
        ${pkgs.iproute2}/bin/ip -4 rule del priority 5201 fwmark ${interface.fwMark} lookup main suppress_prefixlength 0
      '';
    };
  };
}
