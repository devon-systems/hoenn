{inputs, ...}: {
  flake.darwinModules.fallarbor = {
    config,
    self,
    ...
  }: let
    syncthingCert = config.sops.secrets.syncthing-cert.path;
    syncthingKey = config.sops.secrets.syncthing-key.path;
  in {
    imports = [inputs.home-manager.darwinModules.home-manager];

    sops.secrets = {
      syncthing-cert = {
        sopsFile = self + "/secrets/syncthing-fallarbor.yaml";
        key = "cert";
        owner = "aly";
      };

      syncthing-key = {
        sopsFile = self + "/secrets/syncthing-fallarbor.yaml";
        key = "key";
        owner = "aly";
      };
    };

    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {inherit self;};
      useGlobalPkgs = true;
      useUserPackages = true;

      users.aly = {
        home = {
          homeDirectory = "/Users/aly";
          stateVersion = "26.05";
          username = "aly";
        };

        imports = [
          self.homeModules.aly
          self.homeModules.aly-desktop
          self.homeModules.himalaya
          self.homeModules.syncthing
        ];

        hoenn.syncthing = {
          enable = true;
          cert = syncthingCert;
          key = syncthingKey;

          folders.sync.enable = true;
        };
      };
    };
  };
}
