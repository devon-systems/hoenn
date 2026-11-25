_: {
  flake.systemModules.oldale = {config, ...}: {
    # The Determinate installer owns nix.conf and the native daemon units.
    nix.enable = false;
    environment.etc."nix/nix.custom.conf" = {
      replaceExisting = true;
      text = ''
        extra-trusted-users = aly
        extra-substituters = https://cache.numtide.com https://install.determinate.systems https://alyraffauf.cachix.org https://nix-community.cachix.org https://nix-amd-ai.cachix.org https://switchyard.cachix.org
        extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= alyraffauf.cachix.org-1:GQVrRGfjTtkPGS8M6y7Ik0z4zLt77O0N25ynv2gWzDM= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ= switchyard.cachix.org-1:pXDS2Jt8ioyQjcyK4PCs9DFdiOU4POPjAfEvw4gWoxA=
      '';
    };

    systemd.services.determinate-settings = {
      description = "Load managed Determinate Nix settings";
      wantedBy = ["system-manager.target"];
      before = ["home-manager-aly.service"];
      restartTriggers = [config.environment.etc."nix/nix.custom.conf".source];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        /usr/bin/systemctl restart nix-daemon.service
      '';
    };
  };
}
