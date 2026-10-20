{inputs, ...}: let
  cominSettings = {
    enable = true;
    exporter = {
      listen_address = "127.0.0.1";
      port = 4243;
    };

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
      disabledModules = ["system/launchd.nix"];
      imports = [
        inputs.comin.darwinModules.comin
        (import ./_darwin-launchd.nix {inherit inputs;})
      ];

      # Determinate Nix leaves nix-darwin's config.nix.package unavailable.
      launchd.daemons.comin.serviceConfig.EnvironmentVariables = lib.mkForce {
        PATH = "/nix/var/nix/profiles/default/bin:${lib.makeBinPath [
          pkgs.git
          pkgs.openssh
        ]}:/usr/bin:/bin:/usr/sbin:/sbin";
      };

      services.comin =
        cominSettings
        // {
          package = (pkgs.comin or inputs.comin.packages.${pkgs.stdenv.hostPlatform.system}.comin).overrideAttrs (previous: {
            patches = (previous.patches or []) ++ [./_darwin-lifecycle.patch];
            doCheck = true;
            checkPhase = ''
              runHook preCheck
              go test -timeout 60s ./internal/executor ./internal/deployer ./internal/store
              runHook postCheck
            '';
          });
        };
    };
  };
}
