_: {
  flake.nixosModules.mauville = {
    # Mauville sits on the home LAN that the Apple TV advertises as a subnet
    # route. Accepting it would send Mauville's own LAN traffic through Tailscale.
    services.tailscale.extraSetFlags = ["--accept-routes=false"];
  };
}
