{inputs, ...}: let
  peer = inputs.wg-hoenn.lib.network.nodes.petalburg;
in {
  flake.nixosModules.mauville = {self, ...}: {
    imports = [self.nixosModules.wireguardHoennLan];

    networking.wireguard.interfaces.hoenn.peers = [
      {
        name = "petalburg";
        inherit (peer) publicKey;
        allowedIPs = ["${peer.address}/32"];
      }
    ];
  };
}
