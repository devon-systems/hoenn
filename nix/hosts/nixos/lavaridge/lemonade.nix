{inputs, ...}: {
  flake.nixosModules.lavaridge = {
    imports = [inputs.nix-amd-ai.nixosModules.default];

    hardware.amd-npu = {
      enable = true;
      enableNPU = false;
      enableFastFlowLM = false;
      enableImageGen = false;
      enableROCm = true;
      gpuTarget = "gfx1151";

      lemonade = {
        user = "lemonade";
        cacheDir = "/var/lib/lemonade/models";
        desktopApp.enable = false;
        host = "127.0.0.1";
        port = 13305;
        autoStart = true;

        settings = {
          max_loaded_models = 1;
          auto_evict = false;
          global_timeout = 0;
          auto_update_models = false;
          auto_check_model_updates = true;
          telemetry.enabled = false;
          llamacpp.backend = "rocm";
        };
      };

      strata = {
        enable = true;
        quant = "GSQ-RCO-IQ3_S";
        profile = "fast";
        contextSize = 65536;
        expertCache = 6000;
        vision.enable = true;
      };
    };

    users = {
      groups.lemonade = {};

      users.lemonade = {
        isSystemUser = true;
        group = "lemonade";
        extraGroups = ["render" "video"];
        home = "/var/lib/lemonade";
        createHome = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/lemonade/models 0750 lemonade lemonade -"
      "d /var/lib/lemonade/models/hf 0750 lemonade lemonade -"
      "d /var/lib/lemonade/models/lemonade 0750 lemonade lemonade -"
    ];

    nix.settings = {
      substituters = ["https://nix-amd-ai.cachix.org"];
      trusted-public-keys = ["nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ="];
    };
  };
}
