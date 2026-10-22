_: {
  flake.nixosModules.petalburg = {self, ...}: {
    imports = [self.nixosModules.wireguardHoennLan];

    # Use a distinct UDP port from Mauville behind the shared NAT.
    networking.wireguard.interfaces.hoenn.listenPort = 51822;

    networking.wireguard.interfaces.hoenn.peers = [
      {
        name = "mauville";
        publicKey = "DLphP2R9EJ2TbIgaabt5ExQ461TdYX2EjlMsphxkVj8=";
        allowedIPs = ["10.254.1.2/32"];
        endpoint = "192.168.1.243:51821";
        persistentKeepalive = 25;
      }
    ];
  };
}
