_: {
  flake.nixosModules.mauville = {self, ...}: {
    imports = [self.nixosModules.wireguardHoennLan];

    networking.wireguard.interfaces.hoenn.peers = [
      {
        name = "petalburg";
        publicKey = "sodFLJVrTVsifP5ltziHkQrWDwEj+3Cvj6csZbWtgEE=";
        allowedIPs = ["10.254.1.8/32"];
      }
    ];
  };
}
