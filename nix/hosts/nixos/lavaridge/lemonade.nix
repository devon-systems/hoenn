{inputs, ...}: {
  flake.nixosModules.lavaridge = {pkgs, ...}: let
    modelRevision = "d96201194f103c906994f283f504209dc8d2a10c";
    modelCache = "/var/lib/lemonade/models/hf/hub";
    modelDirectory = "${modelCache}/models--unsloth--Qwen3.8-Flash-Next-GGUF/snapshots/${modelRevision}/UD-IQ2_XS";
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
        # The firewall only trusts Tailscale and Hoenn WireGuard, so this
        # stays off the LAN while other Hoenn hosts can reach the API.
        host = "0.0.0.0";
        port = 13305;
        autoStart = true;

        settings = {
          max_loaded_models = 1;
          auto_evict = true;
          # Not an idle timer: this caps HTTP/inference/readiness requests.
          # 0 disables the cap so long agent runs survive (nix-amd-ai #1364).
          global_timeout = 0;
          auto_update_models = false;
          auto_check_model_updates = true;
          telemetry.enabled = false;
          llamacpp.backend = "rocm";
        };

        # Idle eviction: unload the Strata model an hour after its last request
        # (lemonade's default is 300s). Reload is transparent — a request that
        # arrives mid-eviction interrupts it and is served. Strata is registered
        # as a user model, so the recipe_options key needs the user. prefix.
        recipeOptions."user.Qwen3.8-Flash-Next-Strata" = {
          evict_idle_timeout = 3600;
        };
      };

      strata = {
        enable = true;
        model = "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ2_XS-00001-of-00003.gguf";
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
      description = "Download the pinned Strata UD-IQ2_XS model";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "lemonade";
        RemainAfterExit = true;
        TimeoutStartSec = "infinity";
        ExecStart = pkgs.writeShellScript "strata-model-download" ''
          if test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ2_XS-00001-of-00003.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ2_XS-00002-of-00003.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ2_XS-00003-of-00003.gguf"; then
            exit 0
          fi
          exec ${pkgs.huggingface-cli}/bin/hf download unsloth/Qwen3.8-Flash-Next-GGUF \
            --revision ${modelRevision} --include 'UD-IQ2_XS/*' --cache-dir ${modelCache}
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
