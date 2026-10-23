_: {
  flake.nixosModules.nixos = {
    services.journald.settings.Journal = {
      Storage = "persistent";
      SystemMaxUse = "2G";
      SystemKeepFree = "1G";
      MaxRetentionSec = "30day";
    };
  };
}
