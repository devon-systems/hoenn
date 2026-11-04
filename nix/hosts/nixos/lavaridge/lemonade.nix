{inputs, ...}: {
  flake.nixosModules.lavaridge = {pkgs, ...}: let
    modelRevision = "d96201194f103c906994f283f504209dc8d2a10c";
    modelCache = "/var/lib/lemonade/models/hf/hub";
    modelDirectory = "${modelCache}/models--unsloth--Qwen3.8-Flash-Next-GGUF/snapshots/${modelRevision}/UD-IQ1_M";
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
          # Global must stay false: it gates VRAM-pressure polling, and this
          # model's own resident footprint exceeds the 90% threshold.
          auto_evict = false;
          # Not an idle timer: this caps HTTP/inference/readiness requests.
          # 0 disables the cap so long agent runs survive (nix-amd-ai #1364).
          global_timeout = 0;
          auto_update_models = false;
          auto_check_model_updates = true;
          telemetry.enabled = false;
          llamacpp.backend = "rocm";
        };

        # Per-model true keeps idle eviction after an hour while the global
        # false above disables pressure polling. Reload is transparent — a
        # request that arrives mid-eviction interrupts it and is served.
        # Strata is registered as a user model, so the key needs user.
        recipeOptions."user.Qwen3.8-Flash-Next-Strata" = {
          auto_evict = true;
          evict_idle_timeout = 3600;
        };
      };

      strata = {
        enable = true;
        model = "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00001-of-00003.gguf";
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
        # IQ1_M's largest expert blob sizes 12000 slots at 22.0 GiB, like
        # the old GSQ file at 16000. IQ2_XS needed 9000 to fit the pool.
        expertCache = 12000;
        vision.enable = true;
      };
    };

    systemd.services.lemond.environment.STRATA_PREFILL_STREAM_MIN = "128";

    systemd.services.strata-model-download = {
      description = "Download the pinned Strata UD-IQ1_M model";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "lemonade";
        RemainAfterExit = true;
        TimeoutStartSec = "infinity";
        ExecStart = pkgs.writeShellScript "strata-model-download" ''
          if test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00001-of-00003.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00002-of-00003.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00003-of-00003.gguf"; then
            exit 0
          fi
          exec ${pkgs.huggingface-cli}/bin/hf download unsloth/Qwen3.8-Flash-Next-GGUF \
            --revision ${modelRevision} --include 'UD-IQ1_M/*' --cache-dir ${modelCache}
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
