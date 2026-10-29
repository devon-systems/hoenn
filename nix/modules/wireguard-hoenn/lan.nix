{inputs, ...}: {
  flake.nixosModules.wireguardHoennLan = {config, ...}: {
    imports = [inputs.wg-hoenn.nixosModules.lan];
    networking.firewall.allowedUDPPorts = [config.networking.wireguard.interfaces.hoenn.listenPort];
  };
}
