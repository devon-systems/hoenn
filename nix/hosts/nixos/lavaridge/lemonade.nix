{inputs, ...}: {
  flake.nixosModules.lavaridge = {pkgs, ...}: let
    modelRevision = "ed59f92082b1e93c0e96d60a8b11aab089b52f09";
    modelCache = "/var/lib/lemonade/models/hf/hub";
    modelDirectory = "${modelCache}/models--ISTA-DASLab--Qwen3.8-Flash-Next-GSQ-RCO-GGUF/snapshots/${modelRevision}/IQ2_XS";
  in {
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
        model = "${modelDirectory}/Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00001-of-00002.gguf";
        profile = "fast";
        # The pinned engine cannot expand IQ2_XS's draft head in place to Q4_0.
        extraArgs = [
          "--mtp-q4"
          "proj"
          "--prompt-cache"
          "8"
          "--conversation-cache-mib"
          "2048"
          "--conversation-cache-slots"
          "4"
          "--conversation-cache-min-tokens"
          "512"
          "--conversation-cache-min-free-mib"
          "8192"
        ];
        contextSize = 65536;
        expertCache = 16000;
        vision.enable = true;
      };
    };

    systemd.services.lemond.environment.STRATA_PREFILL_STREAM_MIN = "128";

    systemd.services.strata-model-download = {
      description = "Download the pinned Strata IQ2_XS model";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "lemonade";
        RemainAfterExit = true;
        TimeoutStartSec = "infinity";
        ExecStart = pkgs.writeShellScript "strata-model-download" ''
          if test -f "${modelDirectory}/Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00001-of-00002.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00002-of-00002.gguf"; then
            exit 0
          fi
          exec ${pkgs.huggingface-cli}/bin/hf download ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF \
            --revision ${modelRevision} --include 'IQ2_XS/*' --cache-dir ${modelCache}
        '';
      };
    };

    systemd.services.strata-prepare = {
      requires = ["strata-model-download.service"];
      after = ["strata-model-download.service"];
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
