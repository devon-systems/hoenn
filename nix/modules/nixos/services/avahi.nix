_: {
  flake.nixosModules.nixos = {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;

      settings.publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
        publish-workstation = true;
      };
    };
  };
}
