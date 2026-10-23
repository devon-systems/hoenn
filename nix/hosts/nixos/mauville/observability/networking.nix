_: {
  flake.nixosModules.mauville = {
    networking.firewall.interfaces = {
      cni0.allowedTCPPorts = [3020 3030];
      "flannel.1".allowedTCPPorts = [3020 3030];
    };
  };
}
