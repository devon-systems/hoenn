_: {
  flake.nixosModules.lilycove = {
    config,
    self,
    ...
  }: let
    syncthingCert = config.sops.secrets.syncthing-cert.path;
    syncthingKey = config.sops.secrets.syncthing-key.path;
  in {
    sops.secrets = {
      syncthing-cert = {
        sopsFile = self + "/secrets/syncthing-lilycove.yaml";
        key = "cert";
        owner = "aly";
      };

      syncthing-key = {
        sopsFile = self + "/secrets/syncthing-lilycove.yaml";
        key = "key";
        owner = "aly";
      };
    };

    home-manager.users.aly = {
      imports = [self.homeModules.syncthing];

      hoenn.syncthing = {
        enable = true;
        cert = syncthingCert;
        key = syncthingKey;

        folders = {
          sync.enable = true;
        };
      };
    };
  };
}
