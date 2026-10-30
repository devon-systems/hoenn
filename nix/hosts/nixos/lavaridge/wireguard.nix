{inputs, ...}: let
  peer = inputs.wg-hoenn.lib.network.nodes.mauville;
  desktopPeer = inputs.wg-hoenn.lib.network.nodes.petalburg;
in {
  flake.nixosModules.lavaridge = {self, ...}: {
    imports = [self.nixosModules.wireguardHoennLan];

    # Use a distinct UDP port from Mauville and Petalburg behind the shared NAT.
    networking.wireguard.interfaces.hoenn.listenPort = 51823;

    networking.wireguard.interfaces.hoenn.peers = [
      {
        name = "mauville";
        inherit (peer) publicKey;
        allowedIPs = ["${peer.address}/32"];
        endpoint = "192.168.1.243:${toString inputs.wg-hoenn.lib.network.listenPort}";
        persistentKeepalive = 25;
      }
      {
        name = "petalburg";
        inherit (desktopPeer) publicKey;
        allowedIPs = ["${desktopPeer.address}/32"];
        endpoint = "192.168.1.176:51822";
        persistentKeepalive = 25;
      }
    ];
  };
}
