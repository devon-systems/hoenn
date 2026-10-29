{inputs, ...}: let
  peer = inputs.wg-hoenn.lib.network.nodes.mauville;
in {
  flake.nixosModules.petalburg = {self, ...}: {
    imports = [self.nixosModules.wireguardHoennLan];

    # Use a distinct UDP port from Mauville behind the shared NAT.
    networking.wireguard.interfaces.hoenn.listenPort = 51822;

    networking.wireguard.interfaces.hoenn.peers = [
      {
        name = "mauville";
        inherit (peer) publicKey;
        allowedIPs = ["${peer.address}/32"];
        endpoint = "192.168.1.243:51821";
        persistentKeepalive = 25;
      }
    ];
  };
}
