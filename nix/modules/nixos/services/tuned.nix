_: {
  flake.nixosModules.nixos = {
    services.tuned = {
      enable = true;
      settings.dynamic_tuning = true;
    };
  };
}
