_: {
  flake = {
    nixosModules.default = {
      nix.daemonCPUSchedPolicy = "idle";

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        extra-substituters = [
          "https://cache.numtide.com"
          "https://install.determinate.systems"
          "https://alyraffauf.cachix.org"
          "https://switchyard.cachix.org"
        ];

        extra-trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
          "alyraffauf.cachix.org-1:GQVrRGfjTtkPGS8M6y7Ik0z4zLt77O0N25ynv2gWzDM="
          "switchyard.cachix.org-1:pXDS2Jt8ioyQjcyK4PCs9DFdiOU4POPjAfEvw4gWoxA="
        ];

        max-free = 5 * 1024 * 1024 * 1024;
        min-free = 1024 * 1024 * 1024;
      };

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 3d";
        persistent = true;
        randomizedDelaySec = "60min";
      };

      nix.optimise = {
        automatic = true;
        persistent = true;
        randomizedDelaySec = "60min";
      };
    };

    darwinModules.default = {
      nix.enable = false;

      # Determinate manages Nix; the built-in maintenance services require nix.enable.
      launchd.daemons.nix-maintenance = {
        script = ''
          set -eu
          export PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin
          printf '\nNix maintenance started: '
          date
          nix-collect-garbage --delete-older-than 3d
          nix-store --optimise
          printf 'Nix maintenance completed: '
          date
        '';
        serviceConfig = {
          StartCalendarInterval = {
            Hour = 3;
            Minute = 0;
          };
          Nice = 10;
          ProcessType = "Background";
          LowPriorityIO = true;
          StandardOutPath = "/var/log/hoenn-nix-maintenance.log";
          StandardErrorPath = "/var/log/hoenn-nix-maintenance.error.log";
        };
      };
    };
  };
}
