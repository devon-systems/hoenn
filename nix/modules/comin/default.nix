{inputs, ...}: let
  cominSettings = {
    enable = true;

    remotes = [
      {
        name = "origin";
        url = "https://github.com/devon-systems/hoenn.git";
        branches.main.name = "master";
        poller.period = 600;
      }
    ];
  };
in {
  flake = {
    nixosModules.comin = {...}: {
      imports = [inputs.comin.nixosModules.comin];
      services.comin = cominSettings;
    };

    darwinModules.comin = {
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.comin.darwinModules.comin];

      # Determinate Nix leaves nix-darwin's config.nix.package unavailable.
      launchd.daemons.comin.serviceConfig.EnvironmentVariables = lib.mkForce {
        PATH = "/nix/var/nix/profiles/default/bin:${lib.makeBinPath [
          pkgs.git
          pkgs.openssh
        ]}";
      };

      services.comin = cominSettings;
    };
  };
}
