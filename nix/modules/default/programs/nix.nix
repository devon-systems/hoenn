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
    };
  };
}
