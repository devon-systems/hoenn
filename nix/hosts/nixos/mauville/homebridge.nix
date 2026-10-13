_: {
  flake.nixosModules.mauville = _: {
    # HomeKit uses the main bridge and external accessory ports on the LAN.
    networking.firewall.interfaces.wlo1 = {
      allowedTCPPorts = [51826];
      allowedTCPPortRanges = [
        {
          from = 52100;
          to = 52150;
        }
      ];
    };
  };
}
